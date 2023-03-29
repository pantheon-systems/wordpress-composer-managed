#!/bin/bash
# This script is pretty tailored to assuming it's running in the CircleCI environment / a fresh git clone.
# It mirrors most commits from `pantheon-systems/wordpress-composer-managed:release` to `pantheon-upstreams/wordpress-composer-managed`.

# Check github authentication; ignore status code 1 returned from this command
ssh -T git@github.com

# Fail fast on any future errors.
set -euo pipefail

. devops/scripts/commit-type.sh

git remote add public "$UPSTREAM_REPO_REMOTE_URL"
git fetch public
git checkout "${CIRCLE_BRANCH}"

echo
echo "-----------------------------------------------------------------------"
echo "Preparing to release to upstream org"
echo "-----------------------------------------------------------------------"
echo

# List commits between release-pointer and HEAD, in reverse
newcommits=$(git log release-pointer..HEAD --reverse --pretty=format:"%h")
commits=()

# Identify commits that should be released
for commit in $newcommits; do
  commit_type=$(identify_commit_type "$commit")
  if [[ $commit_type == "normal" ]] ; then
    commits+=($commit)
  fi

  if [[ $commit_type == "mixed" ]] ; then
    2>&1 echo "Commit ${commit} contains both release and nonrelease changes. Skipping this commit."
    echo "You may wish to ensure that nothing in this commit is meant for release."
    delete=(${commit})
    for remove in "${delete[@]}"; do
      for i in "${commits[@]}"; do
        if [ [ ${commits[i]} = $remove ]]; then
          unset 'commits[i]'
        fi
      done
    done
  fi
done

# If nothing found to release, bail without doing anything.
if [[ ${#commits[@]} -eq 0 ]] ; then
  echo "No new commits found to release"
  echo "Proceeding to decoulped script"
  echo "https://media.giphy.com/media/cqG5aFdTkk5ig/giphy.gif"
  exit 0
fi

# Cherry-pick commits not modifying circle config onto the release branch
git checkout -b public --track public/main
git pull

if [[ "$CIRCLECI" != "" ]]; then
  git config --global user.email "bot@getpantheon.com"
  git config --global user.name "Pantheon Automation"
fi

for commit in "${commits[@]}"; do
  if [[ -z "$commit" ]] ; then
    continue
  fi
  echo "Adding $commit:"
  git --no-pager log --format=%B -n 1 "$commit"
  git cherry-pick -rn -X theirs "$commit" 2>&1
  # Product request - single commit per release
  # The commit message from the last commit will be used.
  git log --format=%B -n 1 "$commit" > /tmp/commit_message
done

echo "Committing changes"
git commit -F /tmp/commit_message --author='Pantheon Automation <bot@getpantheon.com>'

echo
echo "Releasing to upstream org"
echo

# Push to the public repository
git push public public:main

git checkout $CIRCLE_BRANCH

# update the release-pointer
git tag -f -m 'Last commit set on upstream repo' release-pointer HEAD

# Push release-pointer
git push -f origin release-pointer
