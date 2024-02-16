#!/bin/bash

# ---
# Script to FreeUP Disk Space on Linux Systems
# Author: Enderson Menezes
# Date: 2024-02-16
# Inspired by: https://github.com/jlumbroso/free-disk-space
# ---

# Variables
# ANDROID_FILES: Boolean
# DOTNET_FILES: Boolean
# HASKELL_FILES: Boolean

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

verify_free_disk_space
remove_android_library_folder
verify_free_disk_space

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