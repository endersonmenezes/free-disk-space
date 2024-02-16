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


# Verify Common Packages

# Functions

function verify_free_disk_space(){
    echo "Verifying Free Disk Space"
    df -h
}

function remove_android_library_folder(){
    echo "Removing Android Folder"
    sudo rm -rf /usr/local/lib/android || true
}

function remove_dot_net_library_folder(){
    echo "Removing .NET Folder"
    sudo rm -rf /usr/share/dotnet || true
}

function remove_haskell_library_folder(){
    echo "Removing Haskell Folder"
    sudo rm -rf /opt/ghc || true
    sudo rm -rf /usr/local/.ghcup || true
}

verify_free_disk_space
remove_android_library_folder

verify_free_disk_space
remove_haskeel_library_folder

verify_free_disk_space
remove_haskell_library_folder

echo "Verify other folders on /usr/local/lib"
ls -la /usr/local/lib
echo "---"

echo "Verify size of /usr/local/lib"
du -sh /usr/local/lib
echo "---"

echo "Verify other folder on /usr/share"
ls -la /usr/share
echo "---"

echo "Verify size of /usr/share"
du -sh /usr/share

echo "Verify other folder on /opt"
ls -la /opt
echo "---"

echo "Verify size of /opt"
du -sh /opt

echo "Verify apt list"
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n

