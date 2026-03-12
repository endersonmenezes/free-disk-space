#!/usr/bin/env python3
"""
Test suite for generate-metadata.py size calculations.

This test validates that directory sizes are correctly calculated from ncdu JSON format.
"""

import sys
from pathlib import Path

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent / "scripts"))

# Import directly from the script
import importlib.util
spec = importlib.util.spec_from_file_location("generate_metadata", Path(__file__).parent / "scripts" / "generate-metadata.py")
generate_metadata = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generate_metadata)
get_entry_size = generate_metadata.get_entry_size


def test_file_size():
    """Test that file sizes are correctly calculated."""
    # A file with 1000 bytes apparent size, 4096 disk usage
    file_entry = {"name": "file.txt", "asize": 1000, "dsize": 4096, "ino": 123}

    # Should return dsize (disk usage)
    result = get_entry_size(file_entry)
    expected = 4096

    print(f"Test file_size: {result} == {expected} ? {'PASS' if result == expected else 'FAIL'}")
    assert result == expected, f"Expected {expected}, got {result}"


def test_directory_excludes_metadata():
    """Test that directory size excludes the directory metadata itself."""
    # Directory with two files
    # Directory metadata has asize=4096, dsize=4096 (just the directory inode)
    # Children: file1 (1000/4096) + file2 (2000/4096)
    # Expected: 4096 + 4096 = 8192 (sum of children's dsize only)
    dir_entry = [
        {"name": "testdir", "asize": 4096, "dsize": 4096},  # Directory metadata
        {"name": "file1.txt", "asize": 1000, "dsize": 4096, "ino": 1},
        {"name": "file2.txt", "asize": 2000, "dsize": 4096, "ino": 2}
    ]

    result = get_entry_size(dir_entry)
    expected = 8192  # Sum of children's dsize only

    print(f"Test directory_excludes_metadata: {result} == {expected} ? {'PASS' if result == expected else 'FAIL'}")
    assert result == expected, f"Expected {expected}, got {result}"


def test_nested_directories():
    """Test nested directory structure."""
    # /root
    #   /subdir (4096/4096)
    #     file1.txt (1000/4096)
    #   file2.txt (2000/4096)
    # Expected: 4096 (subdir's file1) + 4096 (root's file2) = 8192
    root_entry = [
        {"name": "root", "asize": 4096, "dsize": 4096},
        [
            {"name": "subdir", "asize": 4096, "dsize": 4096},
            {"name": "file1.txt", "asize": 1000, "dsize": 4096, "ino": 1}
        ],
        {"name": "file2.txt", "asize": 2000, "dsize": 4096, "ino": 2}
    ]

    result = get_entry_size(root_entry)
    expected = 8192  # 4096 + 4096

    print(f"Test nested_directories: {result} == {expected} ? {'PASS' if result == expected else 'FAIL'}")
    assert result == expected, f"Expected {expected}, got {result}"


def test_hardlink_deduplication():
    """Test that hard links are counted only once."""
    # Two entries pointing to the same inode
    dir_entry = [
        {"name": "dir", "asize": 4096, "dsize": 4096},
        {"name": "file1.txt", "asize": 1000, "dsize": 4096, "ino": 123},
        {"name": "file1_link.txt", "asize": 1000, "dsize": 4096, "ino": 123}  # Same inode
    ]

    result = get_entry_size(dir_entry)
    expected = 4096  # Only count once

    print(f"Test hardlink_deduplication: {result} == {expected} ? {'PASS' if result == expected else 'FAIL'}")
    assert result == expected, f"Expected {expected}, got {result}"


def test_empty_directory():
    """Test that empty directories have size 0."""
    empty_dir = [
        {"name": "emptydir", "asize": 4096, "dsize": 4096}
    ]

    result = get_entry_size(empty_dir)
    expected = 0  # No children

    print(f"Test empty_directory: {result} == {expected} ? {'PASS' if result == expected else 'FAIL'}")
    assert result == expected, f"Expected {expected}, got {result}"


if __name__ == "__main__":
    print("Running tests for generate-metadata.py size calculations\n")

    try:
        test_file_size()
        test_directory_excludes_metadata()
        test_nested_directories()
        test_hardlink_deduplication()
        test_empty_directory()
        print("\nAll tests passed! ✓")
    except AssertionError as e:
        print(f"\nTest failed: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\nError running tests: {e}")
        sys.exit(1)
