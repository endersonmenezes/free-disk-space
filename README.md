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