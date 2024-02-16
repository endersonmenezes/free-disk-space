# Free Disk Space - Action

## Inspiration

Free Disk Space Action are inspired by [jlumbroso/free-disk-space](https://github.com/jlumbroso/free-disk-space)

## Local Development

### Mode 1

Needs: https://nektosact.com/installation/index.html

```bash
brew install act
act -P ubuntu-latest=nektos/act-environments-ubuntu:22.04 -j free-disk-space
```

### Mode 2

```bash
export TESTING=true
bash main.sh
```

**Dont forget to export TESTING=true, it make a alias to rm command**