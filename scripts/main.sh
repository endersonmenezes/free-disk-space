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

function remove_android_library_folder(){
    echo "Removing Android Folder"
    sudo rm -rf /usr/local/lib/android || true
}

remove_android_library_folder
