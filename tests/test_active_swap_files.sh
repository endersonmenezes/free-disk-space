#!/bin/bash
# Regression test: remove active swap backing files wherever they are located.
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.." || exit 1; pwd)
WORK=$(mktemp -d)
FAKE_BIN="${WORK}/fake-bin"
COMMAND_LOG="${WORK}/commands.log"
TESTS_COMPLETE="${WORK}/tests-complete"
export COMMAND_LOG

# shellcheck disable=SC2329 # Invoked by the EXIT trap.
cleanup_workdir() {
    local STATUS=$?
    if [[ ! -f "${TESTS_COMPLETE}" ]]; then
        printf 'not ok - harness exited before the assertion summary (status %d)\n' "${STATUS}" >&2
        STATUS=1
    fi
    rm -rf "${WORK}"
    exit "${STATUS}"
}
trap cleanup_workdir EXIT

mkdir -p "${FAKE_BIN}"
: > "${COMMAND_LOG}"

cat > "${FAKE_BIN}/sudo" <<'EOF'
#!/bin/bash
printf 'sudo' >> "${COMMAND_LOG}"
printf ' %s' "$@" >> "${COMMAND_LOG}"
printf '\n' >> "${COMMAND_LOG}"
if [[ "$1" == "swapoff" ]]; then
    if [[ "$2" == "${SWAPOFF_FAIL_PATH:-}" ]]; then
        exit 1
    fi
    exit 0
fi
exec "$@"
EOF

cat > "${FAKE_BIN}/rmz" <<'EOF'
#!/bin/bash
printf 'rmz' >> "${COMMAND_LOG}"
printf ' %s' "$@" >> "${COMMAND_LOG}"
printf '\n' >> "${COMMAND_LOG}"
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
exit 0
EOF
chmod +x "${FAKE_BIN}/sudo" "${FAKE_BIN}/rmz" "${FAKE_BIN}/bc"
export PATH="${FAKE_BIN}:${PATH}"

export PRINCIPAL_DIR="${WORK}" TESTING=false ANDROID_FILES=false DOTNET_FILES=false \
    HASKELL_FILES=false TOOL_CACHE=false SWAP_STORAGE=false PACKAGES=false \
    REMOVE_ONE_COMMAND=false REMOVE_FOLDERS=false RM_CMD=rm RMZ_VERSION=3.2.1 \
    AGENT_TOOLSDIRECTORY=/usr/local/bin GITHUB_REF=refs/heads/test RUNNER_TEMP="${WORK}"

set +e
(
    trap - EXIT
    cd "${WORK}" || exit 1
    # shellcheck source=/dev/null
    source "${REPO_ROOT}/main.sh"

    # Avoid reading or changing host memory state in the regression harness.
    # shellcheck disable=SC2329 # Called by remove_swap_storage.
    free() { :; }

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

    assert_equals() {
        if [[ "$1" == "$2" ]]; then
            ok "$3"
        else
            not_ok "$3" "expected: $1; actual: $2"
        fi
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

    assert_log_contains() {
        if grep -qF -- "$1" "${COMMAND_LOG}"; then ok "$2"; else not_ok "$2" "command log missing: $1"; fi
    }

    assert_log_not_contains() {
        if grep -qF -- "$1" "${COMMAND_LOG}"; then not_ok "$2" "command log unexpected: $1"; else ok "$2"; fi
    }

    assert_empty_log() {
        if [[ ! -s "${COMMAND_LOG}" ]]; then ok "$1"; else not_ok "$1" "commands were executed"; fi
    }

    DISCOVERY_FIXTURE="${WORK}/discovery-swaps"
    cat > "${DISCOVERY_FIXTURE}" <<'EOF'
Filename                                Type    Size    Used    Priority
/swapfile                               file    3145728 0       -2
/mnt/swapfile                           file    1048576 0       -3
/dev/zram0                              partition 1048576 0     5
EOF
    DISCOVERED=$(get_active_swap_files "${DISCOVERY_FIXTURE}")
    assert_equals $'/swapfile\n/mnt/swapfile' "${DISCOVERED}" \
        "discovery returns active file paths, including /swapfile, and excludes partitions"

    run_removal_case() {
        local BACKEND="$1"
        local CASE_DIR="${WORK}/remove-${BACKEND}"
        mkdir -p "${CASE_DIR}"
        local SWAP_ONE="${CASE_DIR}/swapfile"
        local SWAP_TWO="${CASE_DIR}/mnt-swapfile"
        local PARTITION="${CASE_DIR}/zram0"
        : > "${SWAP_ONE}"
        : > "${SWAP_TWO}"
        : > "${PARTITION}"
        : > "${COMMAND_LOG}"
        unset SWAPOFF_FAIL_PATH

        cat > "${CASE_DIR}/swaps" <<EOF
Filename                                Type    Size    Used    Priority
${SWAP_ONE}                             file    3145728 0       -2
${SWAP_TWO}                             file    1048576 0       -3
${PARTITION}                            partition 1048576 0     5
EOF
        RM_CMD="${BACKEND}" TESTING=false PROC_SWAPS_FILE="${CASE_DIR}/swaps" remove_swap_storage

        assert_missing "${SWAP_ONE}" "${BACKEND}: first discovered swap file is removed"
        assert_missing "${SWAP_TWO}" "${BACKEND}: second discovered swap file is removed"
        assert_exists "${PARTITION}" "${BACKEND}: partition backing path is preserved"
        assert_log_contains "sudo swapoff ${SWAP_ONE}" "${BACKEND}: first file is disabled individually"
        assert_log_contains "sudo swapoff ${SWAP_TWO}" "${BACKEND}: second file is disabled individually"
        assert_log_not_contains "${PARTITION}" "${BACKEND}: partition is never passed to swapoff or removal"
    }

    run_removal_case rm
    run_removal_case rmz

    FAILURE_DIR="${WORK}/failed-swapoff"
    mkdir -p "${FAILURE_DIR}"
    FAILED_SWAP="${FAILURE_DIR}/swapfile"
    : > "${FAILED_SWAP}"
    : > "${COMMAND_LOG}"
    cat > "${FAILURE_DIR}/swaps" <<EOF
Filename                                Type    Size    Used    Priority
${FAILED_SWAP}                          file    3145728 0       -2
EOF
    SWAPOFF_FAIL_PATH="${FAILED_SWAP}"
    export SWAPOFF_FAIL_PATH
    OUTPUT=$(RM_CMD=rm TESTING=false PROC_SWAPS_FILE="${FAILURE_DIR}/swaps" remove_swap_storage)
    assert_exists "${FAILED_SWAP}" "failed swapoff preserves the backing file"
    assert_contains "${OUTPUT}" "::warning::Could not disable swap file ${FAILED_SWAP}; leaving it in place" \
        "failed swapoff emits a warning naming the preserved file"
    unset SWAPOFF_FAIL_PATH

    : > "${COMMAND_LOG}"
    cat > "${WORK}/empty-swaps" <<'EOF'
Filename                                Type    Size    Used    Priority
EOF
    OUTPUT=$(RM_CMD=rm TESTING=false PROC_SWAPS_FILE="${WORK}/empty-swaps" remove_swap_storage)
    assert_empty_log "header-only swap data runs no swapoff or removal commands"

    printf '%d assertions, %d failure(s)\n' "${TESTS_RUN}" "${TEST_FAILURES}"
    [[ "${TEST_FAILURES}" == 0 ]]
)
STATUS=$?
set -e
if [[ "${STATUS}" == 0 ]]; then
    touch "${TESTS_COMPLETE}"
fi
exit "${STATUS}"
