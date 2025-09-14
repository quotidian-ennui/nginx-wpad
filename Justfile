set positional-arguments := true
set dotenv-load := true
set unstable := true
set script-interpreter := ['/usr/bin/env', 'bash']

USER := `whoami`
BASE_TAG := USER / "nginx-wpad"

# show recipes
[private]
@help:
    just --list --list-prefix "  "

# Build the image
[group("build")]
@build:
    docker build . --no-cache --tag "{{ BASE_TAG }}:latest" -f "Dockerfile"

# Delete built images
[group("build")]
@clean:
    docker images --format json | jq -r 'select(.Repository | contains("{{ BASE_TAG }}")) | .ID' | xargs -r docker rmi -f || true

# run updatecli with args e.g. just updatecli diff
[group("release")]
@updatecli *action="diff":
    updatecli "$@"

# Show the change log
[group("release")]
@changelog *args="--unreleased":
    git cliff "$@"

# tag and optionally the tag
[group("release")]
[script]
release tag push="localonly":
  #
  set -eo pipefail

  git diff --quiet || (echo "--> git is dirty" && exit 1)
  tag="{{ tag }}"
  push="{{ push }}"
  git tag "$tag" -m"release: $tag"
  case "$push" in
    push|github|gh)
      git push --tags
      ;;
    *)
      ;;
  esac
