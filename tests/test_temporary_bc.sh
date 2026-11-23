#!/bin/bash
# Regression test: bc stays outside the workspace and is removed on every exit.
set -e

REPO_ROOT=$(cd "$(dirname "$0")/.."; pwd)
WORK=$(mktemp -d)
trap 'rm -rf "${WORK}"' EXIT

mkdir -p "${WORK}/bin"
cat > "${WORK}/bin/bc" <<'EOF'
#!/bin/bash
printf '%s\n' "$0" > "${BC_LOG}"
echo '1.00'
EOF
chmod +x "${WORK}/bin/bc"
export PATH="${WORK}/bin:${PATH}"

export PRINCIPAL_DIR="${WORK}" TESTING=true ANDROID_FILES=false DOTNET_FILES=false \
    HASKELL_FILES=false TOOL_CACHE=false SWAP_STORAGE=false PACKAGES=false \
    REMOVE_ONE_COMMAND=false REMOVE_FOLDERS=false RM_CMD=rm RMZ_VERSION=3.2.0 \
    AGENT_TOOLSDIRECTORY=/usr/local/bin GITHUB_REF=refs/heads/test

run_case() {
    local NAME="$1" EXPECTED_STATUS="$2" USE_RUNNER_TEMP="$3"
    local CASE_DIR="${WORK}/$1" STATUS=0 BC_PATH WORKSPACE_FILES
    mkdir -p "${CASE_DIR}/workspace" "${CASE_DIR}/runner temp" "${CASE_DIR}/fallback temp"
    export BC_LOG="${CASE_DIR}/bc.log" TMPDIR="${CASE_DIR}/fallback temp"
    if [[ "${USE_RUNNER_TEMP}" == "true" ]]; then
        export RUNNER_TEMP="${CASE_DIR}/runner temp"
    else
        unset RUNNER_TEMP
    fi

    (
        cd "${CASE_DIR}/workspace"
        bash -e -c '
            source "$1"
            update_and_echo_free_space before
            update_and_echo_free_space after
            if [[ "$2" != 0 ]]; then
                false
            fi
        ' bash "${REPO_ROOT}/main.sh" "${EXPECTED_STATUS}"
    ) > "${CASE_DIR}/output.log" 2>&1 || STATUS=$?

    if [[ "${STATUS}" != "${EXPECTED_STATUS}" || ! -s "${BC_LOG}" ]]; then
        echo "not ok - ${NAME}: expected status ${EXPECTED_STATUS} and a bc invocation, got ${STATUS}"
        cat "${CASE_DIR}/output.log"
        exit 1
    fi
    BC_PATH=$(< "${BC_LOG}")
    if [[ "${BC_PATH}" != "${RUNNER_TEMP:-${TMPDIR}}"/free-disk-space.*/bc ]]; then
        echo "not ok - ${NAME}: unexpected bc path: ${BC_PATH}"
        exit 1
    fi
    WORKSPACE_FILES=$(ls -A "${CASE_DIR}/workspace")
    if [[ -e "${BC_PATH%/bc}" || -n "${WORKSPACE_FILES}" ]]; then
        echo "not ok - ${NAME}: temporary directory or workspace files remain"
        exit 1
    fi
    echo "ok - ${NAME}"
}

run_case 'normal exit' 0 true
run_case 'failed command' 1 true
run_case 'TMPDIR fallback' 0 false

run_setup_failure() {
    local COMMAND="$1" CASE_DIR="${WORK}/failed-$1" STATUS=0 REMAINING_FILES
    mkdir -p "${CASE_DIR}"
    RUNNER_TEMP="${CASE_DIR}" bash -c '
        if [[ "$2" == mktemp ]]; then
            RUNNER_TEMP="${RUNNER_TEMP}/missing"
        else
            cp() { return 1; }
        fi
        source "$1"
    ' bash "${REPO_ROOT}/main.sh" "${COMMAND}" > "${CASE_DIR}.log" 2>&1 || STATUS=$?

    REMAINING_FILES=$(ls -A "${CASE_DIR}")
    if [[ "${STATUS}" != 1 || -n "${REMAINING_FILES}" ]]; then
        echo "not ok - ${COMMAND} failure: expected status 1 and no temporary files, got ${STATUS}"
        cat "${CASE_DIR}.log"
        exit 1
    fi
    echo "ok - ${COMMAND} failure exits with status 1 and leaves no temporary files"
}

run_setup_failure mktemp
run_setup_failure cp
