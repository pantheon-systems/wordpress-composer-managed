#!/bin/bash
# This script does preliminary checks to make sure that the commits in a PR
# made in this repository are ready for the deploy-public-upstream script.
# i.e. any given commit modifies either "normal" or "non-release" files,
# never mixed.

set -euo pipefail

. devops/scripts/commit-type.sh

# List commits between release-pointer and HEAD, in reverse
prcommits=$(git log $(git merge-base default HEAD)..HEAD --pretty=format:"%h")

status=0

# Identify commits that should be released
for commit in $prcommits; do
  commit_type=$(identify_commit_type "$commit")
  if [[ $commit_type == "normal" ]] ; then
    >&2 echo "Commit ${commit} is a normal commit (it modifies only files included in releases)."
  fi

  if [[ $commit_type == "nonrelease" ]] ; then
    >&2 echo "Commit ${commit} is a non-release commit (it modifies only files used internally)."
  fi

  if [[ $commit_type == "mixed" ]] ; then
    >&2 echo "Commit ${commit} contains both release and nonrelease changes. Please split into mutliple commits."
    status=1
  fi

  only_allowed_files=$(only_allowed_files "$commit")
  if [[ $only_allowed_files == "forbidden" ]] ; then
    >&2 echo "Commit ${commit} contains forbidden files. Please remove them."
    status=1
  fi
done

if [[ $status -eq 0 ]] ; then
  >&2 echo "OK to deploy. After merging PR, push the 'release' branch. See README-internal.md"
fi

exit $status
