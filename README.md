# GitHub Hosted Runners Disk Space

[![Collect Disk Space Data](https://github.com/fbnrst/Github-Hosted-Runners-Disk-Space/actions/workflows/collect-disk-space.yml/badge.svg)](https://github.com/fbnrst/Github-Hosted-Runners-Disk-Space/actions/workflows/collect-disk-space.yml)
[![Deploy GitHub Pages](https://github.com/fbnrst/Github-Hosted-Runners-Disk-Space/actions/workflows/deploy-pages.yml/badge.svg)](https://github.com/fbnrst/Github-Hosted-Runners-Disk-Space/actions/workflows/deploy-pages.yml)
[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/fbnrst/Github-Hosted-Runners-Disk-Space/main.svg)](https://results.pre-commit.ci/latest/github/fbnrst/Github-Hosted-Runners-Disk-Space/main)
[![Last Data Update](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Ffbnrst%2FGithub-Hosted-Runners-Disk-Space%2Fdata%2Fdata%2Fx86_64-metadata.json&query=%24.timestamp&label=Last%20Data%20Update&color=blue)](https://fbnrst.github.io/Github-Hosted-Runners-Disk-Space/)

**Automated disk space analysis for GitHub Actions runners** across multiple architectures (x86_64 and aarch64).

## What is this for?

This project helps you:

- **Understand disk usage** on GitHub Actions hosted runners
- **Identify large files and directories** consuming disk space
- **Track changes over time** with automated weekly reports
- **Optimize CI/CD workflows** by knowing what's taking up space

## View Live Reports

**[View Interactive Disk Space Reports](https://fbnrst.github.io/Github-Hosted-Runners-Disk-Space/)**

The web interface provides:

- Interactive tree view to browse directories
- Summary statistics for each architecture
- Fast loading with lazy data fetching

## How to Use

### For Viewing Data

Simply visit the [GitHub Pages site](https://fbnrst.github.io/Github-Hosted-Runners-Disk-Space/) to explore the latest disk space reports.

### For Running Your Own Analysis

Fork this repository and enable GitHub Actions. The workflows will automatically:

- Collect disk space data weekly (every Monday)
- Generate reports and deploy them to GitHub Pages
- Update when you push changes to the `docs/` directory

You can also trigger data collection manually from the Actions tab.

## Documentation

- **[Implementation Details](docs/IMPLEMENTATION.md)** - Technical details about workflows, architecture, and development

## License

This page is open source and available under the BSD 3-Clause License.
