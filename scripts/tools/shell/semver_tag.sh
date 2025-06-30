#!/usr/bin/env bash
set -euo pipefail
set -x  # Enable bash debug output

body="${PR_BODY:-}"
tag="${DEV_TAG:-v0.0.0}"
source="${SOURCE_BRANCH:-}"
target="${TARGET_BRANCH:-}"

# Determine bump type from PR body
bump=""
if echo "$body" | grep -iq '\[x\] *Major'; then
  bump="major"
elif echo "$body" | grep -iq '\[x\] *Minor'; then
  bump="minor"
elif echo "$body" | grep -iq '\[x\] *Patch'; then
  bump="patch"
fi

if [ "$source" = "dev" ] && [ "$target" = "main" ]; then
  # Copy dev tag to main
  final_tag="$tag"
  copy_tag=true
else
  # Fallback to commit message analysis if no bump from PR body
  if [ -z "$bump" ]; then
    if [ "$tag" = "v0.0.0" ]; then
      range="origin/dev"
    else
      range="$tag..origin/dev"
    fi
    commits=$(git log $range --pretty=format:%s)
    bump="patch"
    for msg in $commits; do
      if [[ "$msg" == *"BREAKING CHANGE"* ]]; then
        bump="major"
        break
      elif [[ "$msg" == feat:* && "$bump" != "major" ]]; then
        bump="minor"
      elif [[ "$msg" == fix:* && "$bump" == "patch" ]]; then
        bump="patch"
      fi
    done
  fi
  version=${tag#v}
  IFS='.' read -r major minor patch <<< "$version"
  if [ "$bump" = "major" ]; then
    major=$((major + 1))
    minor=0
    patch=0
  elif [ "$bump" = "minor" ]; then
    minor=$((minor + 1))
    patch=0
  else
    patch=$((patch + 1))
  fi
  next_version="v$major.$minor.$patch"
  # Count only commits on dev since last tag
  if [ "$tag" = "v0.0.0" ]; then
    commit_count=$(git rev-list --count origin/dev)
  else
    commit_count=$(git rev-list --count $tag..origin/dev)
  fi
  final_tag="$next_version.$commit_count"
  copy_tag=false
fi

echo "final_tag=$final_tag" >> "$GITHUB_OUTPUT"
echo "copy_tag=$copy_tag" >> "$GITHUB_OUTPUT"
echo "bump=$bump" >> "$GITHUB_OUTPUT"
echo "[DEBUG] final_tag: $final_tag, copy_tag: $copy_tag, bump: $bump, source: $source, target: $target, tag: $tag" >&2
