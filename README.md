# Free Disk Space - Action

![GitHub License](https://img.shields.io/github/license/endersonmenezes/free-disk-space?label=Project%20License)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/endersonmenezes/free-disk-space/testing.yaml)

## Compatibility

- Ubuntu 22.04 - Tested on 21/08/2025.
- Ubuntu Latest (24.04) - Tested on 21/08/2025.

## Inspiration

Free Disk Space Action are inspired by [jlumbroso/free-disk-space](https://github.com/jlumbroso/free-disk-space)

## Motivation

At work I came across a huge Docker image that still needed to be analyzed by a local security tool. This consumed the entire Runner and in addition to the repository I found, I needed to remove some packages, which led me to create a modification of the original repository.

I will maintain a Stable version of this project.

## Use

```yaml
name: Free Disk Space (Ubuntu)
on:
  - push

jobs:
  free-disk-space:
    runs-on: ubuntu-latest
    steps:
      - name: Free Disk Space
        uses: endersonmenezes/free-disk-space@v2
        with:
          remove_android: true
          remove_dotnet: true
          remove_haskell: true
          remove_tool_cache: true
          remove_swap: true
          remove_packages: "azure-cli google-cloud-cli microsoft-edge-stable google-chrome-stable firefox postgresql* temurin-* *llvm* mysql* dotnet-sdk-*"
          remove_packages_one_command: true
          remove_folders: "/usr/share/swift /usr/share/miniconda /usr/share/az* /usr/local/lib/node_modules /usr/local/share/chromium /usr/local/share/powershell /usr/local/julia /usr/local/aws-cli /usr/local/aws-sam-cli /usr/share/gradle"
          testing: false
```

## Size Savings

`Updated at: 01/08/2025`

| Option | Estimated Size | Time (For some cases) |
| ------ | -------------- | ---- |
| remove_android | 9543.16 MB | 52s |
| remove_dotnet | 32.32 MB MB | 4s |
| remove_haskell | 6460.36 MB | 2s-3s |
| remove_tool_cache | 4844.27 MB | 17s |
| remove_swap | # | # |
| remove_packages_one_command (Example Provided) | 7495.33 MB | 94s |
| folder: /usr/share/swift | 2773.80 MB | # |
| folder: /usr/share/miniconda | 736.06 MB | 9s |
| folder: /usr/share/az | 495.38 MB | 1s |
| folder: /usr/local/lib/node_modules | 463.80 MB | 10s |
| folder: /usr/local/share/chromium | 592.81 MB | 0s |
| folder: /usr/local/share/powershell | 1244.12 MB | 0s |
| folder: /usr/local/aws-cli | 248.41 MB | 1s |
| folder: /usr/local/aws-sam-cli | 189.50 MB | 1s |

_The time can vary according to multiple factors this estimed time based on the run: [#134](https://github.com/endersonmenezes/free-disk-space/actions/runs/16681335178/job/47220484686)_

_In our action you can see more folders and packages to delete, but is your responsibility to know what you are doing._

_Initially I created this project with the intention of doing all this and then being able to use Docker and Python, our tests will prove this._

### Disk After

```text
Run df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        72G   11G   62G  15% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G  1.1M  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
/dev/sda16      881M   60M  760M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
/dev/sdb1        74G   28K   70G   1% /mnt
tmpfs           1.6G   12K  1.6G   1% /run/user/1001
```

## Local Development

The TESTING variable is used to create an alias for the rm command, so that it does not delete the files in the repository.
Are more envs to be added, you will see on main.sh file.

```bash
export TESTING=true
bash main.sh
```

**Don't forget to export TESTING=true, it make a alias to `rm` command**

## Shellcheck

This project uses [pre-commit](https://pre-commit.com/) for shellcheck linting. To run shellcheck:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Run pre-commit hooks on all files
pre-commit run --all-files
```

Alternatively, you can run shellcheck directly:

```bash
shellcheck main.sh -o all -e SC2033,SC2032
```

## Contributing

If you have any questions, please open an issue.

## Acknowledgements

This project, despite being on my personal profile purely formally, is part of an NGO we have in Brazil, responsible for helping young people and adults learn to program and tackle real-world projects. Learn more at [codaqui.dev](https://codaqui.dev).