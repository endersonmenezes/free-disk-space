# Scripts

This directory contains utility scripts for the GitHub Runners Disk Space project.

## generate-metadata.py

Generates lightweight metadata files from full NCDU JSON reports for faster page loading.

### What it does

- Extracts essential information (architecture, timestamp, runner, total size)
- Includes all directory entries
- Creates `-metadata.json` files alongside the full JSON files
- Reduces file sizes by 90-97% (e.g., 56MB → 600 bytes)

### Usage

```bash
python3 scripts/generate-metadata.py
```

The script automatically:

- Finds all JSON files in `docs/data/` directory
- Processes files that don't end with `-metadata.json`
- Generates corresponding metadata files
- Reports size reduction for each file

### When it runs

This script is automatically executed by the `collect-disk-space.yml` workflow after downloading new disk space reports, ensuring metadata files are always up-to-date.

### File format

Metadata files contain:

```json
{
  "architecture": "x86_64",
  "timestamp": "2026-02-05",
  "runner": "ubuntu-24.04",
  "total_size": 111179272497,
  "top_entries": [[size, "name", has_children], ...],
  "total_entries": 27
}
```

This format enables the web interface to:

1. Load quickly with minimal data
2. Display top-level information immediately
3. Lazy-load full data only when users expand directories
