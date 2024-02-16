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
# PACKAGES: String (separated by space)
# SIMULTANEOUS: Boolean (true or false)
# TOOL_CACHE: Boolean (true or false)
# SWAP_STORAGE: Boolean (true or false)

# Validate Variables
if [ -z "$PRINCIPAL_DIR" ]; then
    echo "Variable PRINCIPAL_DIR is not set"
    exit 0
fi
if [[ $TESTING == "true" ]]; then
    echo "Testing Mode"
    alias rm='echo rm'
fi
if [ -z "$ANDROID_FILES" ]; then
    echo "Variable ANDROID_FILES is not set"
    exit 0
fi
if [ -z "$DOTNET_FILES" ]; then
    echo "Variable DOTNET_FILES is not set"
    exit 0
fi
if [ -z "$HASKELL_FILES" ]; then
    echo "Variable HASKELL_FILES is not set"
    exit 0
fi
if [ -z "$PACKAGES" ]; then
    echo "Variable PACKAGES is not set"
    exit 0
fi
if [[ $PACKAGES != "false" ]]; then
    if [[ $PACKAGES != *" "* ]]; then
        echo "Variable PACKAGES is not a list of strings"
        exit 0
    fi
fi
if [ -z "$SIMULTANEOUS" ]; then
    echo "Variable SIMULTANEOUS is not set"
    exit 0
fi
if [ -z "$TOOL_CACHE" ]; then
    echo "Variable TOOL_CACHE is not set"
    exit 0
fi
if [ -z "$SWAP_STORAGE" ]; then
    echo "Variable SWAP_STORAGE is not set"
    exit 0
fi

# Global Variables
TOTAL_FREE_SPACE=0

# Verify Needed Packages

# Verify BC
if ! [ -x "$(command -v bc)" ]; then
    echo 'Error: bc is not installed.' >&2
    exit 1
fi

# Functions

function verify_free_disk_space(){
    df -B1 "$PRINCIPAL_DIR" | awk 'NR==2 {print $4}'
}

function convert_bytes_to_mb(){
    echo "scale=2; $1 / 1024 / 1024" | bc
}

function verify_free_space_in_mb(){
    convert_bytes_to_mb "$(verify_free_disk_space)"
}

function update_and_echo_free_space(){
    IS_AFTER_OR_BEFORE=$1
    if [ "$IS_AFTER_OR_BEFORE" == "before" ]; then
        SPACE_BEFORE=$(verify_free_space_in_mb)
        LINUX_TIMESTAMP_BEFORE=$(date +%s)
    else
        SPACE_AFTER=$(verify_free_space_in_mb)
        LINUX_TIMESTAMP_AFTER=$(date +%s)
        FREEUP_SPACE=$(echo "scale=2; $SPACE_AFTER - $SPACE_BEFORE" | bc)
        echo "FreeUp Space: $FREEUP_SPACE MB"
        echo "Time Elapsed: $((LINUX_TIMESTAMP_AFTER - LINUX_TIMESTAMP_BEFORE)) seconds"
        TOTAL_FREE_SPACE=$(echo "scale=2; $TOTAL_FREE_SPACE + $FREEUP_SPACE" | bc)
    fi
}

function remove_android_library_folder(){
    echo "🤖 Removing Android Folder"
    update_and_echo_free_space "before"
    rm -rf /usr/local/lib/android || true
    update_and_echo_free_space "after"
    echo "-"
}

function remove_dot_net_library_folder(){
    echo "📄 Removing .NET Folder"
    update_and_echo_free_space "before"
    rm -rf /usr/share/dotnet || true
    update_and_echo_free_space "after"
    echo "-"
}

function remove_haskell_library_folder(){
    echo "📄 Removing Haskell Folder"
    update_and_echo_free_space "before"
    rm -rf /opt/ghc || true
    rm -rf /usr/local/.ghcup || true
    update_and_echo_free_space "after"
    echo "-"
}

function remove_package(){
    PACKAGE_NAME=$1
    echo "📦 Removing $PACKAGE_NAME"
    update_and_echo_free_space "before"
    apt-get remove -y "$PACKAGE_NAME" --fix-missing > /dev/null
    apt-get autoremove -y > /dev/null
    apt-get clean > /dev/null
    apt-get update > /dev/null
    update_and_echo_free_space "after"
    echo "-"
}

function remove_tool_cache(){
    echo "🧹 Removing Tool Cache"
    update_and_echo_free_space "before"
    rm -rf "$AGENT_TOOLSDIRECTORY" || true
    update_and_echo_free_space "after"
    echo "-"
}

function remove_swap_storage(){
    echo "🧹 Removing Swap Storage"
    update_and_echo_free_space "before"
    swapoff -a || true
    rm -f "/mnt/swapfile" || true
    update_and_echo_free_space "after"
    echo "-"
}

# Remove Libraries
function main(){
    if [[ $ANDROID_FILES == "true" ]]; then
        remove_android_library_folder
    fi
    if [[ $DOTNET_FILES == "true" ]]; then
        remove_dot_net_library_folder
    fi
    if [[ $HASKELL_FILES == "true" ]]; then
        remove_haskell_library_folder
    fi
    if [[ $PACKAGES != "false" ]]; then
        if [[ $SIMULTANEOUS == "true" ]]; then
            remove_package "$PACKAGES"
        else
            for PACKAGE in $PACKAGES; do
                remove_package "$PACKAGE"
            done
        fi
    fi
    if [[ $TOOL_CACHE == "true" ]]; then
        remove_tool_cache
    fi
    if [[ $SWAP_STORAGE == "true" ]]; then
        remove_swap_storage
    fi
    echo "Total Free Space: $TOTAL_FREE_SPACE MB"
}

sh -c main

# Echo
echo "🎉 FreeUP Disk Space Finished"
df -h
