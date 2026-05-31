set positional-arguments
set dotenv-load
set unstable
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
    git cliff "$@" 2>/dev/null

# Show the next version based on nginx bumps
[group("release")]
[script]
next:
    set -eo pipefail

    lastTag=$(git tag | sort -rV | head -n1)
    version=$(git log --format=format:'%s' "$lastTag"..HEAD | grep -i "Bump nginx from" | sed -E "s/^.* to ([0-9]+\.[0-9]+\.[0-9]+).*$/\1/g" | sort -rV | head -n1) || true
    if [[ -z "$version" ]]; then
      echo "No Version bump of activemq found?"
      echo "lastTag was $lastTag"
      exit 1
    else
      echo "$version"
    fi

# Auto compute tag and optionally push
[group("release")]
[script]
please-release push="localonly":
    set -eo pipefail

    next=$(just next)
    echo "ℹ️ Tag & release $next"
    just release "$next" {{ push }}

alias autotag := please-release

# tag and optionally push tag
[group("release")]
[script]
release tag push="localonly":
    #
    set -eo pipefail

    check_uptodate() {
      remote_hash=$(git ls-remote origin refs/heads/main | cut -f1)
      local_hash=$(git rev-parse "$(git branch --show-current)")
      if [[ "$remote_hash" != "$local_hash" ]]; then
        echo "⚠️ Remote hash differs, are we up to date?"
        exit 1
      fi
    }

    git diff --quiet || (echo "⚠️ git is dirty" && exit 1)
    check_uptodate
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
