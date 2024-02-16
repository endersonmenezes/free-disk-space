#!/bin/bash

# ---
# Script to FreeUP Disk Space on Linux Systems
# Author: Enderson Menezes
# Date: 2024-02-16
# Inspired by: https://github.com/jlumbroso/free-disk-space
# ---

# Variables
# PRINCIPAL_DIR: String
# ANDROID_FILES: Boolean

# Validate Variables
if [ -z "$ANDROID_FILES" ]; then
    echo "Variable ANDROID_FILES is not set"
    exit 0
fi
if [ -z "$PRINCIPAL_DIR" ]; then
    echo "Variable PRINCIPAL_DIR is not set"
    exit 0
fi
if [[ $TESTING == "true" ]]; then
    echo "Testing Mode"
    alias rm='echo rm'
fi

# Global Variables
TOTAL_FREE_SPACE=0


# Verify Common Packages

# Verify BC
if ! [ -x "$(command -v bc)" ]; then
    echo 'Error: bc is not installed.' >&2
    exit 1
fi

# Functions

function verify_free_disk_space(){
    df -B1 $PRINCIPAL_DIR | awk 'NR==2 {print $4}'
}

function convert_bytes_to_mb(){
    echo "scale=2; $1 / 1024 / 1024" | bc
}

function verify_free_space_in_mb(){
    convert_bytes_to_mb $(verify_free_disk_space)
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
        echo "Time Elapsed: $(($LINUX_TIMESTAMP_AFTER - $LINUX_TIMESTAMP_BEFORE)) seconds"
        TOTAL_FREE_SPACE=$(echo "scale=2; $TOTAL_FREE_SPACE + $FREEUP_SPACE" | bc)
    fi
}

function remove_android_library_folder(){
    echo "🤖 Removing Android Folder"
    update_and_echo_free_space "before"
    sudo rm -rf /usr/local/lib/android || true
    update_and_echo_free_space "after"
    echo ""
}

function remove_dot_net_library_folder(){
    echo "📄 Removing .NET Folder"
    update_and_echo_free_space "before"
    sudo rm -rf /usr/share/dotnet || true
    update_and_echo_free_space "after"
    echo ""
}

function remove_haskell_library_folder(){
    echo "📄 Removing Haskell Folder"
    update_and_echo_free_space "before"
    sudo rm -rf /opt/ghc || true
    sudo rm -rf /usr/local/.ghcup || true
    update_and_echo_free_space "after"
    echo ""
}

function remove_azure_cli_packages(){
    echo "📦 Removing Azure CLI Packages"
    update_and_echo_free_space "before"
    sudo apt-get remove -y azure-cli
    sudo apt-get autoremove -y
    update_and_echo_free_space "after"
    echo ""
}

# Remove Libraries
remove_android_library_folder
remove_dot_net_library_folder
remove_haskell_library_folder
remove_azure_cli_packages

echo "Total Free Space: $TOTAL_FREE_SPACE MB"

## -- Testing Zone -- ##

# echo "Verify other folders on /usr/local/lib"
# ls -la /usr/local/lib
# echo "---"

# echo "Verify size of /usr/local/lib"
# du -sh /usr/local/lib
# echo "---"

# echo "Verify other folder on /usr/share"
# ls -la /usr/share
# echo "---"

# echo "Verify size of /usr/share"
# du -sh /usr/share

# echo "Verify other folder on /opt"
# ls -la /opt
# echo "---"

# echo "Verify size of /opt"
# du -sh /opt

# echo "Verify apt list"
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n

