#!/usr/bin/env python3
"""
Generate lightweight metadata files from full NCDU JSON reports.
These metadata files contain only essential information for quick page load.
"""

import json
import sys
from pathlib import Path


def extract_entry_info(entry, max_depth=1, current_depth=0):
    """Extract essential information from an NCDU entry, limiting depth."""
    if not isinstance(entry, list) or len(entry) < 2:
        return None

    size = entry[0]
    name = entry[1]

    result = [size, name]

    # Include children only up to max_depth
    if current_depth < max_depth and len(entry) > 2:
        # Indicate that children exist but don't include full data
        result.append({"has_children": True, "child_count": len(entry) - 2})

    return result


def get_entry_size(entry, seen_inodes=None):
    """Calculate total size of an NCDU entry.

    According to NCDU documentation:
    - For files: dsize represents the disk usage (allocated blocks)
    - For directories: The metadata dict contains only the directory inode size
      (typically 4096 bytes). The total directory size is the sum of all children.

    Hard links (files with the same inode) are only counted once to avoid
    overestimation of disk usage.

    Args:
        entry: The NCDU entry to calculate size for
        seen_inodes: Set of inodes already counted (used internally for recursion)

    Returns:
        Total disk usage in bytes (using dsize field)
    """
    if seen_inodes is None:
        seen_inodes = set()

    if isinstance(entry, dict):
        # File entry: check for hard links
        ino = entry.get('ino')
        if ino is not None:
            # This file has an inode number
            if ino in seen_inodes:
                # Already counted this inode (hard link)
                return 0
            # Mark this inode as seen
            seen_inodes.add(ino)

        # Return dsize (disk usage) only, not asize + dsize
        return entry.get('dsize', 0)
    elif isinstance(entry, list) and len(entry) >= 1:
        # Directory entry: [metadata, children...]
        # According to ncdu format, directory size = sum of children only
        # The metadata dict contains only the directory inode size, not the total
        total_size = 0

        # Sum only children's sizes, not the directory metadata
        for i in range(1, len(entry)):
            child = entry[i]
            total_size += get_entry_size(child, seen_inodes)

        return total_size
    return 0


def generate_metadata(input_file, output_file):
    """Generate metadata file with lightweight summary."""
    with open(input_file, 'r') as f:
        data = json.load(f)

    # Extract metadata
    metadata = {
        "architecture": data.get("architecture"),
        "timestamp": data.get("timestamp"),
        "runner": data.get("runner"),
        "total_disk_size": data.get("total_disk_size"),
        "available_space": data.get("available_space"),
    }

    # Parse NCDU data structure: [version, timestamp, metadata, root_entry, ...children]
    ncdu_data = data.get("data", [])
    if len(ncdu_data) > 3:
        # ncdu_data[3] is the root directory entry (list with metadata and children)
        root_entry = ncdu_data[3]

        if isinstance(root_entry, list) and len(root_entry) > 0:
            # First element is metadata dict with name, asize, dsize
            root_meta = root_entry[0]
            if isinstance(root_meta, dict):
                # Calculate total from all children
                total_size = get_entry_size(root_entry)
                metadata["total_size"] = total_size

            # Get all child entries (starting from index 1)
            # Calculate sizes with a shared seen_inodes set to avoid overestimating
            # when hard links exist between top-level entries
            top_level_entries = []
            shared_inodes = set()
            count = 0
            for i in range(1, len(root_entry)):
                entry = root_entry[i]

                if isinstance(entry, list) and len(entry) > 0:
                    # Entry is [metadata, ...children]
                    entry_meta = entry[0]
                    if isinstance(entry_meta, dict):
                        name = entry_meta.get('name', 'unknown')
                        # Use shared inode set to properly handle hard links
                        size = get_entry_size(entry, shared_inodes)
                        has_children = len(entry) > 1
                        top_level_entries.append([size, name, has_children])
                        count += 1
                elif isinstance(entry, dict):
                    # Entry is just metadata (file, not directory)
                    name = entry.get('name', 'unknown')
                    # Use shared inode set to properly handle hard links
                    size = get_entry_size(entry, shared_inodes)
                    top_level_entries.append([size, name, False])
                    count += 1

            metadata["top_entries"] = top_level_entries
            metadata["total_entries"] = len(root_entry) - 1  # -1 for metadata

    # Write metadata file
    with open(output_file, 'w') as f:
        json.dump(metadata, f, separators=(',', ':'))

    print(f"Generated {output_file}")

    # Print size comparison
    input_size = Path(input_file).stat().st_size
    output_size = Path(output_file).stat().st_size
    reduction = (1 - output_size / input_size) * 100
    print(f"  Size: {input_size:,} → {output_size:,} bytes ({reduction:.1f}% reduction)")


def main():
    """Process all JSON files in docs/data directory."""
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    data_dir = repo_root / "docs" / "data"

    if not data_dir.exists():
        print(f"Error: Data directory not found: {data_dir}")
        sys.exit(1)

    json_files = list(data_dir.glob("*.json"))
    metadata_files = [f for f in json_files if not f.name.endswith("-metadata.json")]

    if not metadata_files:
        print("No JSON files found to process")
        sys.exit(1)

    for json_file in metadata_files:
        output_file = json_file.parent / f"{json_file.stem}-metadata.json"
        try:
            generate_metadata(json_file, output_file)
        except Exception as e:
            print(f"Error processing {json_file}: {e}", file=sys.stderr)
            sys.exit(1)

    print(f"\nSuccessfully generated {len(metadata_files)} metadata files")


if __name__ == "__main__":
    main()
