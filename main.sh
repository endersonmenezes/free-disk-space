#!/bin/bash

# ---
# Script to FreeUP Disk Space on Linux Systems
# Author: Enderson Menezes
# Date: 2024-02-16
# Inspired by: https://github.com/jlumbroso/free-disk-space
# ---

# Variables
# PRINCIPAL_DIR: String
# TESTING: Boolean (true or false)
# ANDROID_FILES: Boolean (true or false)
# DOTNET_FILES: Boolean (true or false)
# HASKELL_FILES: Boolean (true or false)
# TOOL_CACHE: Boolean (true or false)
# SWAP_STORAGE: Boolean (true or false)
# PACKAGES: String (separated by space)
# REMOVE_ONE_COMMAND: Boolean (true or false)
# REMOVE_FOLDERS: String (separated by space)

# Environment Variables
# AGENT_TOOLSDIRECTORY: String
# GITHUB_REF: String

# Validate Variables
if [[ -z "${PRINCIPAL_DIR}" ]]; then
    echo "Variable PRINCIPAL_DIR is not set"
    exit 0
fi
if [[ -z "${TESTING}" ]]; then
    TESTING="false"
fi
if [[ ${TESTING} == "true" ]]; then
    echo "Testing Mode"
    echo "We are running com GitHub Branch: ${GITHUB_REF}"
    alias rm='echo rm'
fi
if [[ -z "${ANDROID_FILES}" ]]; then
    echo "Variable ANDROID_FILES is not set"
    exit 0
fi
if [[ -z "${DOTNET_FILES}" ]]; then
    echo "Variable DOTNET_FILES is not set"
    exit 0
fi
if [[ -z "${HASKELL_FILES}" ]]; then
    echo "Variable HASKELL_FILES is not set"
    exit 0
fi
if [[ -z "${TOOL_CACHE}" ]]; then
    echo "Variable TOOL_CACHE is not set"
    exit 0
fi
if [[ -z "${SWAP_STORAGE}" ]]; then
    echo "Variable SWAP_STORAGE is not set"
    exit 0
fi
if [[ -z "${PACKAGES}" ]]; then
    echo "Variable PACKAGES is not set"
    exit 0
fi
if [[ ${PACKAGES} != "false" ]]; then
    if [[ ${PACKAGES} != *" "* ]]; then
        echo "Variable PACKAGES is not a list of strings"
        exit 0
    fi
fi
if [[ -z "${REMOVE_ONE_COMMAND}" ]]; then
    echo "Variable REMOVE_ONE_COMMAND is not set"
    exit 0
fi
if [[ -z "${REMOVE_FOLDERS}" ]]; then
    echo "Variable REMOVE_FOLDERS is not set"
    exit 0
fi
if [[ -z "${AGENT_TOOLSDIRECTORY}" ]]; then
    echo "Variable AGENT_TOOLSDIRECTORY is not set"
    exit 0
fi

# Validate Automatic Variables
if [[ -z "${GITHUB_REF}" ]]; then
    echo "Variable GITHUB_REF is not set"
fi

# Global Variables
TOTAL_FREE_SPACE=0

# Verify Needed Packages

# Verify BC and install if needed
COMMAND_BC=$(command -v bc)
if ! [[ -x "${COMMAND_BC}" ]]; then
    echo 'bc is not installed. Attempting to install...' >&2
    # Try to install bc on ubuntu
    COMMAND_APT_GET=$(command -v apt-get)
    if [[ -x "${COMMAND_APT_GET}" ]]; then
        echo "Installing bc on Ubuntu..."
        sudo apt-get update
        sudo apt-get install -y bc
        # Verify installation was successful
        COMMAND_BC=$(command -v bc)
        if ! [[ -x "${COMMAND_BC}" ]]; then
            echo 'Error: Failed to install bc.' >&2
            exit 1
        fi
    else
        echo 'Error: bc is not installed and apt-get is not available to install it.' >&2
        exit 1
    fi
else
    if [[ ${TESTING} == "true" ]]; then
        echo "Found bc at: ${COMMAND_BC}"
    fi
    sudo chmod +x "${COMMAND_BC}"
    alias bc='${COMMAND_BC}'
fi

# Functions

function verify_free_disk_space(){
    FREE_SPACE_TMP=$(df -B1 "${PRINCIPAL_DIR}")
    echo "${FREE_SPACE_TMP}" | awk 'NR==2 {print $4}'
}

function convert_bytes_to_mb(){
    echo "scale=2; $1 / 1024 / 1024" | bc
}

function verify_free_space_in_mb(){
    DATA_TO_CONVERT=$(verify_free_disk_space)
    convert_bytes_to_mb "${DATA_TO_CONVERT}"
}

function update_and_echo_free_space(){
    IS_AFTER_OR_BEFORE=$1
    if [[ "${IS_AFTER_OR_BEFORE}" == "before" ]]; then
        SPACE_BEFORE=$(verify_free_space_in_mb)
        LINUX_TIMESTAMP_BEFORE=$(date +%s)
    else
        SPACE_AFTER=$(verify_free_space_in_mb)
        LINUX_TIMESTAMP_AFTER=$(date +%s)
        FREEUP_SPACE=$(echo "scale=2; ${SPACE_AFTER} - ${SPACE_BEFORE}" | bc)
        echo "FreeUp Space: ${FREEUP_SPACE} MB"
        echo "Time Elapsed: $((LINUX_TIMESTAMP_AFTER - LINUX_TIMESTAMP_BEFORE)) seconds"
        TOTAL_FREE_SPACE=$(echo "scale=2; ${TOTAL_FREE_SPACE} + ${FREEUP_SPACE}" | bc)
    fi
}

function remove_android_library_folder(){
    echo "🤖 Removing Android Folder"
    update_and_echo_free_space "before"
    
    # Remove Android SDK directories (common locations)
    sudo rm -rf /usr/local/lib/android || true
    sudo rm -rf /opt/android || true
    sudo rm -rf /usr/local/android-sdk || true
    sudo rm -rf /home/runner/Android || true
    
    # Remove Android packages if they exist
    ANDROID_PACKAGES=$(dpkg -l | grep -E "^ii.*(android|adb)" | awk '{print $2}' | tr '\n' ' ' || true)
    if [[ -n "${ANDROID_PACKAGES}" ]]; then
        echo "Removing Android packages: ${ANDROID_PACKAGES}"
        sudo apt-get remove -y "${ANDROID_PACKAGES}" --fix-missing > /dev/null 2>&1 || true
        sudo apt-get autoremove -y > /dev/null 2>&1 || true
        sudo apt-get clean > /dev/null 2>&1 || true
    fi
    
    update_and_echo_free_space "after"
    echo "-"
}

function remove_dot_net_library_folder(){
    echo "📄 Removing .NET Folder"
    update_and_echo_free_space "before"
    
    # Remove .NET installation directories
    sudo rm -rf /usr/share/dotnet || true
    
    # Remove .NET documentation directories
    sudo rm -rf /usr/share/doc/dotnet-* || true
    
    # Remove .NET packages if they exist
    DOTNET_PACKAGES=$(dpkg -l | grep -E "^ii.*dotnet" | awk '{print $2}' | tr '\n' ' ' || true)
    if [[ -n "${DOTNET_PACKAGES}" ]]; then
        echo "Removing .NET packages: ${DOTNET_PACKAGES}"
        sudo apt-get remove -y "${DOTNET_PACKAGES}" --fix-missing > /dev/null 2>&1 || true
        sudo apt-get autoremove -y > /dev/null 2>&1 || true
        sudo apt-get clean > /dev/null 2>&1 || true
    fi
    
    update_and_echo_free_space "after"
    echo "-"
}

function remove_haskell_library_folder(){
    echo "📄 Removing Haskell Folder"
    update_and_echo_free_space "before"
    
    # Remove Haskell directories
    sudo rm -rf /opt/ghc || true
    sudo rm -rf /usr/local/.ghcup || true
    sudo rm -rf /opt/cabal || true
    sudo rm -rf /home/runner/.ghcup || true
    sudo rm -rf /home/runner/.cabal || true
    
    # Remove Haskell packages if they exist
    HASKELL_PACKAGES=$(dpkg -l | grep -E "^ii.*(ghc|haskell|cabal)" | awk '{print $2}' | tr '\n' ' ' || true)
    if [[ -n "${HASKELL_PACKAGES}" ]]; then
        echo "Removing Haskell packages: ${HASKELL_PACKAGES}"
        sudo apt-get remove -y "${HASKELL_PACKAGES}" --fix-missing > /dev/null 2>&1 || true
        sudo apt-get autoremove -y > /dev/null 2>&1 || true
        sudo apt-get clean > /dev/null 2>&1 || true
    fi
    
    update_and_echo_free_space "after"
    echo "-"
}

function remove_package(){
    PACKAGE_NAME=$1
    echo "📦 Removing ${PACKAGE_NAME}"
    update_and_echo_free_space "before"
    sudo apt-get remove -y "${PACKAGE_NAME}" --fix-missing > /dev/null
    sudo apt-get autoremove -y > /dev/null
    sudo apt-get clean > /dev/null
    update_and_echo_free_space "after"
    echo "-"
}

function remove_multi_packages_one_command(){
    PACKAGES_TO_REMOVE=$1
    MOUNT_COMMAND="sudo apt-get remove -y"
    for PACKAGE in ${PACKAGES_TO_REMOVE}; do
        MOUNT_COMMAND+=" ${PACKAGE}"
    done
    echo "📦 Removing ${PACKAGES_TO_REMOVE}"
    update_and_echo_free_space "before"
    ${MOUNT_COMMAND} --fix-missing > /dev/null
    sudo apt-get autoremove -y > /dev/null
    sudo apt-get clean > /dev/null
    update_and_echo_free_space "after"
    echo "-"
}

function remove_tool_cache(){
    echo "🧹 Removing Tool Cache"
    update_and_echo_free_space "before"
    sudo rm -rf "${AGENT_TOOLSDIRECTORY}" || true
    update_and_echo_free_space "after"
    echo "-"
}

function remove_swap_storage(){
    # eye emoji see swap
    echo "👁️‍🗨️ See Swap"
    free -h
    echo "🧹 Removing Swap Storage"
    sudo swapoff -a || true
    sudo rm -f "/mnt/swapfile" || true
    echo "🧹 Removed Swap Storage"
    free -h
    echo "-"
}

function remove_folder(){
    FOLDER=$1
    echo "📁 Removing ${FOLDER}"
    update_and_echo_free_space "before"
    sudo rm -rf "${FOLDER}" || true
    update_and_echo_free_space "after"
}

# Remove Libraries
if [[ ${ANDROID_FILES} == "true" ]]; then
    remove_android_library_folder
fi
if [[ ${DOTNET_FILES} == "true" ]]; then
    remove_dot_net_library_folder
fi
if [[ ${HASKELL_FILES} == "true" ]]; then
    remove_haskell_library_folder
fi
if [[ ${PACKAGES} != "false" ]]; then
    if [[ ${REMOVE_ONE_COMMAND} == "true" ]]; then
        remove_multi_packages_one_command "${PACKAGES}"
    else
        for PACKAGE in ${PACKAGES}; do
            remove_package "${PACKAGE}"
        done
    fi
fi
if [[ ${TOOL_CACHE} == "true" ]]; then
    remove_tool_cache
fi
if [[ ${SWAP_STORAGE} == "true" ]]; then
    remove_swap_storage
fi
if [[ ${REMOVE_FOLDERS} != "false" ]]; then
    for FOLDER in ${REMOVE_FOLDERS}; do
        remove_folder "${FOLDER}"
    done
fi
echo "Total Free Space: ${TOTAL_FREE_SPACE} MB"