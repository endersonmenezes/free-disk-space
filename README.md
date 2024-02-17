# Free Disk Space - Action

![GitHub License](https://img.shields.io/github/license/endersonmenezes/free-disk-space?label=Project%20License)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/endersonmenezes/free-disk-space/testing.yaml)


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
        uses: endersonmenezes/free-disk-space@main
        with:
          remove_android: true
          remove_dotnet: true
          remove_haskell: true
          remove_tool_cache: true
          remove_swap: true
          remove_packages: "azure-cli google-cloud-cli microsoft-edge-stable google-chrome-stable firefox postgresql* temurin-* *llvm* mysql*"
          remove_packages_one_command: ${{ matrix.one_command }}
          testing: false
```

## Size Savings

`Updated at: 17/02/2024`

| Option | Estimated Size | Time (For some cases) |
| ------ | -------------- | ---- |
| remove_android | 9036.34 MB | 64s~79s |
| remove_dotnet | 1583.80 MB | 1s-2s |
| remove_haskell | 5384.87 MB | 3s-5s |
| remove_tool_cache | 9009.73 MB | 4s-6s |
| remove_swap | # | # |
| remove_packages_one_command (Example Provided) | 6846.01 MB | 101s |
| package: azure-cli | 857.67 MB | 27s |
| package: google-cloud-cli | 1002.64 MB | 77s |
| package: microsoft-edge-stable | 553.15 MB | 4s |
| package: google-chrome-stable | 324.53 MB | 4s |
| package: firefox | 240.50 MB | 5s |
| package: postgresql* | 61.51 MB | 7s |
| package: temurin-* | 989.17 MB | 11s |
| package: *llvm* | 2467.68 MB | 14s |
| package: mysql* | 347.55 MB | 5s |

_The time can vary according to multiple factors this estimed time based on the run: [#96](https://github.com/endersonmenezes/free-disk-space/actions/runs/7941840875/job/21684563626)_


## Local Development

The TESTING variable is used to create an alias for the rm command, so that it does not delete the files in the repository.
Are more envs to be added, you will see on main.sh file.

```bash
export TESTING=true
bash main.sh
```

**Don't forget to export TESTING=true, it make a alias to `rm` command**

## Shellcheck

```bash
shellcheck main.sh -o all -e SC2033,SC2032
```

## Contributing

If you have any questions, please open an issue.