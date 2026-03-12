# Implementation Details

This document provides technical details about how the GitHub Self-Hosted Runners Disk Space project works.

## How It Works

1. **Data Collection**: The `collect-disk-space.yml` workflow uses `ncdu` (NCurses Disk Usage) to scan the filesystem on both x86_64 and aarch64 runners
2. **Metadata Generation**: Lightweight metadata files are automatically generated from full reports for fast page loading
3. **Data Storage**: Results are exported to JSON format with metadata (timestamp, architecture, runner type) and committed to a separate `data` branch to avoid conflicts with page design changes
4. **Page Deployment**: The `deploy-pages.yml` workflow automatically deploys updates to GitHub Pages when changes are made to the `docs/` directory (excluding data files)
5. **Visualization**: An interactive HTML page displays the data with expandable tree views and lazy-loaded details by fetching from the `data` branch

## Workflows

### Data Collection Workflow

The data collection workflow (`collect-disk-space.yml`) runs weekly to gather disk usage information:

- **Schedule**: Every Monday at 00:00 UTC
- **Trigger**: Can also be manually triggered via `workflow_dispatch`
- **Process**:
  1. Runs ncdu on x86_64 and aarch64 runners in parallel
  2. Generates JSON reports with metadata
  3. Creates lightweight metadata files for fast page loading
  4. Commits reports to a separate `data` branch

### Pages Deployment Workflow

The pages deployment workflow (`deploy-pages.yml`) is triggered by:

- **Automatic**: After the "Collect Disk Space Data" workflow completes successfully
- **Automatic**: On push to `docs/` directory for layout/design changes (data files are excluded since they're in a separate branch)
- **Manual**: Via `workflow_dispatch`
- **Process**: Deploys the `docs/` directory to GitHub Pages

This setup ensures that:

- The GitHub Pages site is automatically updated after new data is collected
- Page layouts can be updated independently without conflicting with data updates
- Data collection runs on a schedule without unnecessary page deployments when data hasn't changed
- PRs for page design changes don't have merge conflicts from data updates
- Only the latest data version is kept without history (stored in separate `data` branch)

## Manual Workflow Trigger

You can manually trigger the workflows from the Actions tab:

### Data Collection

1. Go to the "Actions" tab
2. Select "Collect Disk Space Data" workflow
3. Click "Run workflow"

### Pages Deployment

1. Go to the "Actions" tab
2. Select "Deploy GitHub Pages" workflow
3. Click "Run workflow"

## Workflow Schedule

The data collection workflow runs automatically:

- **Schedule**: Every Monday at 00:00 UTC

The pages deployment workflow runs automatically:

- **After Data Collection**: Triggered automatically when the "Collect Disk Space Data" workflow completes successfully
- **On Layout Changes**: On push to `docs/` directory (e.g., when layout or design changes are made)

Both workflows can also be manually triggered via `workflow_dispatch` (see "Manual Workflow Trigger" section above).

## Technical Details

- **Tool**: ncdu (NCurses Disk Usage) v1.15+
- **Format**: JSON export format
- **Runners**:
  - x86_64: `ubuntu-latest`
  - aarch64: `ubuntu-latest-arm64`

## Development

### Pre-commit Hooks

This repository uses pre-commit hooks to maintain code quality. To set up:

```bash
pip install pre-commit
pre-commit install
```

The hooks will automatically check:

- Trailing whitespace
- End of file fixers
- YAML syntax validation
- JSON syntax validation
- Large file detection
- Merge conflict markers

## Repository Structure

### Main Branch

```none
.
├── .github/
│   └── workflows/
│       ├── collect-disk-space.yml          # Data collection workflow (weekly)
│       ├── collect-disk-space-template.yml # Reusable workflow template
│       └── deploy-pages.yml                # GitHub Pages deployment workflow
├── .pre-commit-config.yaml                 # Pre-commit hooks configuration
├── docs/
│   ├── index.html                          # GitHub Pages viewer (fetches data from data branch)
│   └── IMPLEMENTATION.md                   # This file
├── scripts/
│   ├── generate-metadata.py               # Metadata extraction script
│   └── README.md                           # Scripts documentation
└── README.md
```

### Data Branch (Separate, No History)

```none
data/
├── x86_64.json                     # Full NCDU data (~56MB)
├── x86_64-metadata.json            # Lightweight metadata (~600 bytes)
├── aarch64.json                    # Full NCDU data (~24MB)
├── aarch64-metadata.json           # Lightweight metadata (~600 bytes)
└── ... (other architecture data files)
```

The `data` branch is an orphan branch that stores only the latest version of data files to:

- Avoid merge conflicts with page design PRs
- Keep the main branch history clean
- Reduce repository size (no data file history)
