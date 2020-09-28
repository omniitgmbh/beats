#! /usr/bin/env bash

set -eu
set -o pipefail

# Prepare repo
git remote add upstream "https://github.com/${UPSTREAM_REPO}.git"

## Fetch tags from all remotes (otherwise we do not know about origin tags)
git fetch --tags --all --force --quiet

# Local tags, https://github.com/koalaman/shellcheck/wiki/SC2207
local_tags=()
while IFS='' read -r line; do local_tags+=("$line"); done < <(git ls-remote --tags origin | sed 's#.*refs/tags/##' | grep -v '{}$' | sort)

# Remote tags (upstream)
remote_tags=()
while IFS='' read -r line; do remote_tags+=("$line"); done < <(git ls-remote --tags upstream | sed 's#.*refs/tags/##' | grep -v '{}$' | sort)

# Get the tags that are only available in the upstream repo
# FIXME: Fix SC2006 without breaking the logic
# shellcheck disable=SC2207,2006
new_upstream_tags=(`echo "${local_tags[@]}" "${remote_tags[@]}" | tr ' ' '\n' | sort | uniq -u `)

# ultra hacky json creation
json_pre="{\"include\": ["
json_post="]}"

json_seperator=""
json_content=""
for new_tag in "${new_upstream_tags[@]}"; do
  new_tag_commitish=$(git rev-list -n 1 "${new_tag}")
  echo New upstream tag found: "${new_tag_commitish} ${new_tag}"
  json_content="${json_content}${json_seperator}{\"tag\": \"${new_tag}\", \"commitish\": \"${new_tag_commitish}\"}"
  json_seperator=","
done

matrix="${json_pre}${json_content}${json_post}"
echo "::set-output name=matrix::${matrix}"
