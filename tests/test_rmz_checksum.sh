#!/bin/bash
# Regression test: every rmz download must pass SHA-256 verification before
# sudo install, while pinned defaults and the rm path remain compatible.

REPO_ROOT=$(cd "$(dirname "$0")/.." || exit 1; pwd)
WORK=$(mktemp -d)
FAKE_BIN="${WORK}/fake-bin"
trap 'rm -rf "${WORK}"' EXIT

X86_64_SHA="7dc19b56caeab9611b578355bbc58c791d1830177651817dec339e0e926286ce"
AARCH64_SHA="49f6aaddf00ac3e4ae2a7928d1d651ea708b0bedd577a94d08ece44414cf3a36"
CUSTOM_SHA="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
TESTS_RUN=0
TEST_FAILURES=0

mkdir -p "${FAKE_BIN}"

cat > "${FAKE_BIN}/curl" <<'EOF'
#!/bin/bash
OUTPUT=""
URL=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o)
            OUTPUT="$2"
            shift 2
            ;;
        -*)
            shift
            ;;
        *)
            URL="$1"
            shift
            ;;
    esac
done
printf '%s\n' "${URL}" >> "${CURL_LOG}"
printf 'fake rmz payload\n' > "${OUTPUT}"
EOF

cat > "${FAKE_BIN}/sudo" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "${SUDO_LOG}"
EOF

cat > "${FAKE_BIN}/sha256sum" <<'EOF'
#!/bin/bash
if [[ "${1:-}" != "-c" || "${2:-}" != "-" ]]; then
    printf 'unexpected sha256sum arguments: %s\n' "$*" >&2
    exit 2
fi
read -r EXPECTED FILE
printf '%s\n' "${EXPECTED}" > "${SHA_LOG}"
if [[ "${EXPECTED}" == "${FAKE_SHA256}" ]]; then
    printf '%s: OK\n' "${FILE}"
    exit 0
fi
printf '%s: FAILED\n' "${FILE}"
exit 1
EOF

cat > "${FAKE_BIN}/uname" <<'EOF'
#!/bin/bash
if [[ "${1:-}" == "-m" ]]; then
    printf '%s\n' "${FAKE_ARCH}"
else
    /usr/bin/uname "$@"
fi
EOF

cat > "${FAKE_BIN}/bc" <<'EOF'
#!/bin/bash
exit 0
EOF

cat > "${FAKE_BIN}/rmz" <<'EOF'
#!/bin/bash
exit 0
EOF

chmod +x "${FAKE_BIN}/curl" "${FAKE_BIN}/sudo" "${FAKE_BIN}/sha256sum" \
    "${FAKE_BIN}/uname" "${FAKE_BIN}/bc" "${FAKE_BIN}/rmz"

run_case() {
    CASE_DIR="${WORK}/$1"
    local VERSION="$2"
    local ARCH="$3"
    local ACTUAL_SHA="$4"
    local COMMAND="$5"
    local PROVIDED_SHA="$6"
    mkdir -p "${CASE_DIR}"
    : > "${CASE_DIR}/curl.log"
    : > "${CASE_DIR}/sudo.log"
    : > "${CASE_DIR}/sha.log"
    (
        cd "${CASE_DIR}" || exit 1
        env PATH="${FAKE_BIN}:${PATH}" \
            FAKE_ARCH="${ARCH}" FAKE_SHA256="${ACTUAL_SHA}" \
            CURL_LOG="${CASE_DIR}/curl.log" SUDO_LOG="${CASE_DIR}/sudo.log" \
            SHA_LOG="${CASE_DIR}/sha.log" \
            PRINCIPAL_DIR="${CASE_DIR}" TESTING=false ANDROID_FILES=false \
            DOTNET_FILES=false HASKELL_FILES=false TOOL_CACHE=false \
            SWAP_STORAGE=false PACKAGES=false REMOVE_ONE_COMMAND=false \
            REMOVE_FOLDERS=false RM_CMD="${COMMAND}" RMZ_VERSION="${VERSION}" \
            RMZ_SHA256="${PROVIDED_SHA}" AGENT_TOOLSDIRECTORY=/usr/local/bin \
            GITHUB_REF=refs/heads/test bash "${REPO_ROOT}/main.sh"
    ) > "${CASE_DIR}/output.log" 2>&1
}

ok() {
    TESTS_RUN=$((TESTS_RUN + 1))
    printf 'ok - %s\n' "$1"
}

not_ok() {
    TESTS_RUN=$((TESTS_RUN + 1))
    printf 'not ok - %s\n#   %s\n' "$1" "$2"
    TEST_FAILURES=$((TEST_FAILURES + 1))
}

assert_contains() {
    if printf '%s' "$1" | grep -qF -- "$2"; then
        ok "$3"
    else
        not_ok "$3" "missing: $2"
    fi
}

assert_file_equals() {
    local ACTUAL
    ACTUAL=$(<"$1")
    if [[ "${ACTUAL}" == "$2" ]]; then
        ok "$3"
    else
        not_ok "$3" "expected: $2; got: ${ACTUAL}"
    fi
}

assert_file_contains() {
    if grep -qF -- "$2" "$1"; then
        ok "$3"
    else
        not_ok "$3" "missing from $1: $2"
    fi
}

assert_file_empty() {
    if [[ ! -s "$1" ]]; then
        ok "$2"
    else
        not_ok "$2" "expected empty file: $1"
    fi
}

run_case pinned-x86_64 3.2.0 x86_64 "${X86_64_SHA}" rmz ""
assert_file_equals "${CASE_DIR}/sha.log" "${X86_64_SHA}" \
    "pinned x86_64: verifies the pinned checksum"
assert_file_equals "${CASE_DIR}/curl.log" \
    "https://github.com/SUPERCILEX/fuc/releases/download/3.2.0/x86_64-unknown-linux-gnu-rmz" \
    "pinned x86_64: downloads the existing asset"
assert_file_contains "${CASE_DIR}/sudo.log" "install -m 0755" \
    "pinned x86_64: valid checksum permits installation"

run_case pinned-aarch64 3.2.0 aarch64 "${AARCH64_SHA}" rmz ""
assert_file_equals "${CASE_DIR}/sha.log" "${AARCH64_SHA}" \
    "pinned aarch64: verifies the architecture-specific checksum"
assert_file_equals "${CASE_DIR}/curl.log" \
    "https://github.com/SUPERCILEX/fuc/releases/download/3.2.0/aarch64-unknown-linux-gnu-rmz" \
    "pinned aarch64: downloads the existing asset"
assert_file_contains "${CASE_DIR}/sudo.log" "install -m 0755" \
    "pinned aarch64: valid checksum permits installation"

run_case checksum-mismatch 3.2.0 x86_64 "${CUSTOM_SHA}" rmz ""
assert_file_equals "${CASE_DIR}/sha.log" "${X86_64_SHA}" \
    "mismatch: checks the downloaded file against the pin"
assert_file_empty "${CASE_DIR}/sudo.log" "mismatch: never invokes sudo install"
assert_contains "$(<"${CASE_DIR}/output.log")" \
    "rmz checksum verification failed; refusing installation" \
    "mismatch: reports the verification failure"

run_case custom-missing 9.9.9 x86_64 "${CUSTOM_SHA}" rmz ""
assert_file_empty "${CASE_DIR}/curl.log" "custom missing: fails before downloading"
assert_file_empty "${CASE_DIR}/sudo.log" "custom missing: never invokes sudo install"
assert_contains "$(<"${CASE_DIR}/output.log")" \
    "RMZ_SHA256 is required for unpinned rmz version 9.9.9" \
    "custom missing: explains that an explicit checksum is required"

run_case custom-malformed 9.9.9 x86_64 "${CUSTOM_SHA}" rmz "not-a-sha"
assert_file_empty "${CASE_DIR}/curl.log" "custom malformed: fails before downloading"
assert_file_empty "${CASE_DIR}/sudo.log" "custom malformed: never invokes sudo install"
assert_contains "$(<"${CASE_DIR}/output.log")" \
    "RMZ_SHA256 must be exactly 64 hexadecimal characters" \
    "custom malformed: reports the checksum format"

run_case custom-valid 9.9.9 x86_64 "${CUSTOM_SHA}" rmz "${CUSTOM_SHA}"
assert_file_equals "${CASE_DIR}/sha.log" "${CUSTOM_SHA}" \
    "custom valid: verifies the supplied checksum"
assert_file_equals "${CASE_DIR}/curl.log" \
    "https://github.com/SUPERCILEX/fuc/releases/download/9.9.9/x86_64-unknown-linux-gnu-rmz" \
    "custom valid: preserves the requested version"
assert_file_contains "${CASE_DIR}/sudo.log" "install -m 0755" \
    "custom valid: valid checksum permits installation"

run_case pinned-override 3.2.0 x86_64 "${CUSTOM_SHA}" rmz "${CUSTOM_SHA}"
assert_file_equals "${CASE_DIR}/sha.log" "${CUSTOM_SHA}" \
    "pinned override: an explicit checksum takes precedence"
assert_file_contains "${CASE_DIR}/sudo.log" "install -m 0755" \
    "pinned override: valid explicit checksum permits installation"

run_case rm-unchanged 3.2.0 x86_64 "${X86_64_SHA}" rm ""
assert_file_empty "${CASE_DIR}/curl.log" "rm: does not download rmz"
assert_file_empty "${CASE_DIR}/sudo.log" "rm: does not install rmz"
assert_file_empty "${CASE_DIR}/sha.log" "rm: does not require an rmz checksum"
assert_contains "$(<"${CASE_DIR}/output.log")" "Total Recovered Space: 0 MB" \
    "rm: main script completes without new inputs"

printf '%d assertions, %d failure(s)\n' "${TESTS_RUN}" "${TEST_FAILURES}"
if [[ ${TEST_FAILURES} -gt 0 ]]; then
    exit 1
fi
