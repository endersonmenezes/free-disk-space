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

verify_free_disk_space
remove_android_library_folder
verify_free_disk_space
