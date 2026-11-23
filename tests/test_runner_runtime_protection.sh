#!/bin/bash
# Regression test: remove_folders must never delete the active GitHub Actions
# Node.js runtime, even when the runner's cached externals resolve under a
# requested parent such as /opt/runner-cache.
#
# The harness sources main.sh with every cleanup flag disabled, overrides disk
# measurement (portable across GNU/BSD df), and confines fake sudo/rmz doubles
# to a temporary directory. Run from anywhere:
#   bash tests/test_runner_runtime_protection.sh

REPO_ROOT=$(cd "$(dirname "$0")/.." || exit 1; pwd)

WORK=$(mktemp -d)
FAKE_BIN="${WORK}/fake-bin"
RMZ_LOG="${WORK}/rmz.log"
LAYOUT=""
TESTS_COMPLETE=0
export RMZ_LOG

# Never let the harness pass without running its assertions: main.sh exits
# during sourcing when a prerequisite (e.g. bc) is missing, which would
# otherwise end the whole script with status 0 before any assertion runs.
cleanup_workdir() {
    local STATUS=$?
    rm -rf "${WORK}"
    if [[ ${TESTS_COMPLETE} -ne 1 ]]; then
        printf 'not ok - harness exited before the assertion summary; ' >&2
        printf 'main.sh likely exited early during sourcing (status was %d)\n' "${STATUS}" >&2
        exit 1
    fi
    exit "${STATUS}"
}
trap cleanup_workdir EXIT

mkdir -p "${FAKE_BIN}"
: > "${RMZ_LOG}"

# --- doubles confined to the temporary directory ------------------------------

cat > "${FAKE_BIN}/sudo" <<'EOF'
#!/bin/bash
# Double for sudo: run the command as the current user.
exec "$@"
EOF

cat > "${FAKE_BIN}/rmz" <<'EOF'
#!/bin/bash
# Double for rmz: record the invocation, then remove like rm -rf.
printf '%s\n' "$*" >> "${RMZ_LOG}"
RMZ_PATHS=()
for ARG in "$@"; do
    case "${ARG}" in
        -*) ;;
        *) RMZ_PATHS+=("${ARG}") ;;
    esac
done
if [[ ${#RMZ_PATHS[@]} -gt 0 ]]; then
    /bin/rm -rf "${RMZ_PATHS[@]}"
fi
EOF

cat > "${FAKE_BIN}/bc" <<'EOF'
#!/bin/bash
# Double for bc: only needs to satisfy command -v and the cp in main.sh; the
# harness overrides disk measurement, so this is never actually invoked.
exit 0
EOF
chmod +x "${FAKE_BIN}/sudo" "${FAKE_BIN}/rmz" "${FAKE_BIN}/bc"
export PATH="${FAKE_BIN}:${PATH}"

if ! command -v nproc >/dev/null 2>&1; then
    # GNU coreutils on the runners; absent on BSD/macOS hosts.
    nproc() { printf '2\n'; }
fi

# --- source main.sh with all cleanup flags disabled ---------------------------

export PRINCIPAL_DIR="${WORK}" TESTING=false ANDROID_FILES=false DOTNET_FILES=false \
    HASKELL_FILES=false TOOL_CACHE=false SWAP_STORAGE=false PACKAGES=false \
    REMOVE_ONE_COMMAND=false REMOVE_FOLDERS=false RM_CMD=rm RMZ_VERSION=3.2.1 \
    AGENT_TOOLSDIRECTORY=/usr/local/bin GITHUB_REF=refs/heads/test

# main.sh copies bc into the current directory at source time, so source it
# from the temporary working directory instead of the repository.
cd "${WORK}" || exit 1
# shellcheck source=/dev/null
source "${REPO_ROOT}/main.sh"

# Disk measurement override: production uses GNU df -B1; keep the harness
# portable to any host.
update_and_echo_free_space() { :; }

# --- assertion helpers --------------------------------------------------------

TESTS_RUN=0
TEST_FAILURES=0

ok() {
    TESTS_RUN=$((TESTS_RUN + 1))
    printf 'ok - %s\n' "$1"
}

not_ok() {
    TESTS_RUN=$((TESTS_RUN + 1))
    printf 'not ok - %s\n#   %s\n' "$1" "$2"
    TEST_FAILURES=$((TEST_FAILURES + 1))
}

assert_exists() {
    if [[ -e "$1" ]]; then ok "$2"; else not_ok "$2" "expected to exist: $1"; fi
}

assert_missing() {
    if [[ ! -e "$1" ]]; then ok "$2"; else not_ok "$2" "expected to be removed: $1"; fi
}

assert_contains() {
    if printf '%s' "$1" | grep -qF -- "$2"; then ok "$3"; else not_ok "$3" "missing: $2"; fi
}

assert_not_contains() {
    if printf '%s' "$1" | grep -qF -- "$2"; then not_ok "$3" "unexpected: $2"; else ok "$3"; fi
}

assert_no_warning() {
    if printf '%s' "$1" | grep -q '::warning::'; then not_ok "$2" "unexpected warning: $1"; else ok "$2"; fi
}

assert_log_contains() {
    if grep -qF -- "$1" "${RMZ_LOG}"; then ok "$2"; else not_ok "$2" "rmz log missing: $1"; fi
}

assert_log_not_contains() {
    if grep -qF -- "$1" "${RMZ_LOG}"; then not_ok "$2" "rmz log unexpected: $1"; else ok "$2"; fi
}

WARNING_PREFIX='::warning::Skipping '
WARNING_SUFFIX=': it overlaps the active GitHub Actions Node.js runtime'

# --- layout: fake runner home whose cached node24 externals resolve into
# --- a requested parent directory (mirrors /opt/runner-cache layouts) ---------

new_layout() {
    LAYOUT=$(mktemp -d "${WORK}/layout.XXXXXX")
    MARKER="${LAYOUT}/opt/runner-cache/externals/node24/marker.txt"
    mkdir -p "${LAYOUT}/runner-home/cached/2.338.2/externals" \
        "${LAYOUT}/opt/runner-cache/externals/node24/lib" \
        "${LAYOUT}/opt/runner-cache/unrelated-dir" \
        "${LAYOUT}/opt/other-folder"
    printf 'runtime marker\n' > "${MARKER}"
    printf 'archive\n' > "${LAYOUT}/opt/runner-cache/installer.tar.gz"
    printf 'unrelated\n' > "${LAYOUT}/opt/runner-cache/unrelated-dir/file.txt"
    ln -s "${LAYOUT}/opt/runner-cache/externals/node24" \
        "${LAYOUT}/runner-home/cached/2.338.2/externals/node24"
    : > "${RMZ_LOG}"
}

remove_with() {
    RM_CMD="$1" TESTING="$2" RUNNER_HOME="$3" remove_folders "$4"
}

# --- rm mode: real deletion inside the temporary layout -----------------------

new_layout
OUTPUT=$(remove_with rm false "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache ${LAYOUT}/opt/other-folder")
assert_exists "${MARKER}" "rm: requested parent runner-cache keeps runtime marker"
assert_exists "${LAYOUT}/opt/runner-cache/installer.tar.gz" "rm: skipped parent keeps siblings"
assert_missing "${LAYOUT}/opt/other-folder" "rm: unrelated folder still removed"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt/runner-cache${WARNING_SUFFIX}" \
    "rm: warning emitted for requested parent"

new_layout
OUTPUT=$(remove_with rm false "${LAYOUT}/runner-home" "${LAYOUT}/opt")
assert_exists "${MARKER}" "rm: requested parent opt keeps runtime marker"
assert_exists "${LAYOUT}/opt/other-folder" "rm: requested parent opt skips the whole tree with warning"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt${WARNING_SUFFIX}" \
    "rm: warning emitted for requested parent opt"

new_layout
if RUNNER_HOME="${LAYOUT}/runner-home" is_active_runner_runtime_path /; then
    ok "rm: predicate reports root as overlapping the runtime"
else
    not_ok "rm: predicate reports root as overlapping the runtime" "expected exit 0 for candidate /"
fi
assert_exists "${MARKER}" "rm: predicate-only check deletes nothing"

new_layout
OUTPUT=$(remove_with rm false "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache/externals/node24")
assert_exists "${MARKER}" "rm: requested runtime path itself is skipped"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt/runner-cache/externals/node24${WARNING_SUFFIX}" \
    "rm: warning emitted for runtime path"

new_layout
OUTPUT=$(remove_with rm false "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache/externals/node24/lib")
assert_exists "${MARKER}" "rm: requested path below runtime keeps marker"
assert_exists "${LAYOUT}/opt/runner-cache/externals/node24/lib" \
    "rm: requested path below runtime is skipped"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt/runner-cache/externals/node24/lib${WARNING_SUFFIX}" \
    "rm: warning emitted for nested path"

new_layout
OUTPUT=$(remove_with rm false "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache/installer.tar.gz ${LAYOUT}/opt/runner-cache/unrelated-dir")
assert_exists "${MARKER}" "rm: runtime marker untouched by sibling cleanup"
assert_missing "${LAYOUT}/opt/runner-cache/installer.tar.gz" "rm: installer archive removed"
assert_missing "${LAYOUT}/opt/runner-cache/unrelated-dir" "rm: unrelated runner-cache dir removed"
assert_no_warning "${OUTPUT}" "rm: no warning for safe siblings"

new_layout
EMPTY_RUNNER_HOME=$(mktemp -d "${WORK}/empty-runner-home.XXXXXX")
OUTPUT=$(remove_with rm false "${EMPTY_RUNNER_HOME}" "${LAYOUT}/opt/runner-cache")
assert_missing "${MARKER}" "rm: no-runtime layout keeps old behavior (folder removed)"
assert_no_warning "${OUTPUT}" "rm: no-runtime layout emits no warning"

new_layout
OUTPUT=$(remove_with rm false "" "${LAYOUT}/opt/runner-cache")
assert_missing "${MARKER}" "rm: default RUNNER_HOME fallback keeps old behavior (folder removed)"
assert_no_warning "${OUTPUT}" "rm: default RUNNER_HOME fallback emits no warning"

new_layout
OUTPUT=$(remove_with rm true "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache ${LAYOUT}/opt/other-folder")
assert_exists "${MARKER}" "testing rm: nothing deleted"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt/runner-cache${WARNING_SUFFIX}" \
    "testing rm: warning emitted for protected path"
assert_not_contains "${OUTPUT}" "rm -r -f ${LAYOUT}/opt/runner-cache" \
    "testing rm: no removal command for protected path"
assert_contains "${OUTPUT}" "rm -r -f ${LAYOUT}/opt/other-folder" \
    "testing rm: safe removal still echoed"

# --- rmz mode: sequential loop driven by the fake rmz double -------------------

new_layout
OUTPUT=$(remove_with rmz false "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache ${LAYOUT}/opt/other-folder")
assert_exists "${MARKER}" "rmz: requested parent runner-cache keeps runtime marker"
assert_missing "${LAYOUT}/opt/other-folder" "rmz: unrelated folder still removed"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt/runner-cache${WARNING_SUFFIX}" \
    "rmz: warning emitted for requested parent"
assert_log_not_contains "${LAYOUT}/opt/runner-cache" "rmz: fake rmz never saw protected path"
assert_log_contains "${LAYOUT}/opt/other-folder" "rmz: fake rmz removed unrelated folder"

new_layout
OUTPUT=$(remove_with rmz false "${LAYOUT}/runner-home" "${LAYOUT}/opt")
assert_exists "${MARKER}" "rmz: requested parent opt keeps runtime marker"
assert_exists "${LAYOUT}/opt/other-folder" "rmz: requested parent opt skips the whole tree with warning"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt${WARNING_SUFFIX}" \
    "rmz: warning emitted for requested parent opt"

new_layout
OUTPUT=$(remove_with rmz false "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache/installer.tar.gz ${LAYOUT}/opt/runner-cache/unrelated-dir")
assert_exists "${MARKER}" "rmz: runtime marker untouched by sibling cleanup"
assert_missing "${LAYOUT}/opt/runner-cache/installer.tar.gz" "rmz: installer archive removed"
assert_missing "${LAYOUT}/opt/runner-cache/unrelated-dir" "rmz: unrelated runner-cache dir removed"
assert_no_warning "${OUTPUT}" "rmz: no warning for safe siblings"

new_layout
OUTPUT=$(remove_with rmz false "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache/externals/node24")
assert_exists "${MARKER}" "rmz: requested runtime path itself is skipped"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt/runner-cache/externals/node24${WARNING_SUFFIX}" \
    "rmz: warning emitted for runtime path"
assert_log_not_contains "externals/node24" "rmz: fake rmz never saw runtime path"

new_layout
OUTPUT=$(remove_with rmz true "${LAYOUT}/runner-home" \
    "${LAYOUT}/opt/runner-cache ${LAYOUT}/opt/other-folder")
assert_exists "${MARKER}" "testing rmz: nothing deleted"
assert_contains "${OUTPUT}" "${WARNING_PREFIX}${LAYOUT}/opt/runner-cache${WARNING_SUFFIX}" \
    "testing rmz: warning emitted for protected path"
assert_not_contains "${OUTPUT}" "rmz -f ${LAYOUT}/opt/runner-cache" \
    "testing rmz: no removal command for protected path"
assert_contains "${OUTPUT}" "rmz -f ${LAYOUT}/opt/other-folder" \
    "testing rmz: safe removal still echoed"

# --- summary -------------------------------------------------------------------

printf '%d assertions, %d failure(s)\n' "${TESTS_RUN}" "${TEST_FAILURES}"
TESTS_COMPLETE=1
if [[ ${TEST_FAILURES} -gt 0 ]]; then
    exit 1
fi
