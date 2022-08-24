#!/bin/bash
# This script is pretty tailored to assuming it's running in the CircleCI environment / a fresh git clone.
# It mirrors most commits from `pantheon-systems/drupal-composer-managed:release` to `pantheon-upstreams/drupal-composer-managed`.

# Check github authentication; ignore status code 1 returned from this command
ssh -T git@github.com

# Fail fast on any future errors.
set -euo pipefail

. devops/scripts/commit-type.sh

git remote add decoupled "$UPSTREAM_DECOUPLED_REPO_REMOTE_URL"
git fetch decoupled
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
    2>&1 echo "Commit ${commit} contains both release and nonrelease changes. Cannot proceed."
    exit 1
  fi
done

# If nothing found to release, bail without doing anything.
if [[ ${#commits[@]} -eq 0 ]] ; then
  echo "No new commits found to release"
  echo "https://i.kym-cdn.com/photos/images/newsfeed/001/240/075/90f.png"
  exit 1
fi

# Copy patch and README file to tmp directory for use after checkout.
echo "Copying decoupledpatch and decoupled-README to /tmp for use later."
cp devops/scripts/decoupledpatch.sh /tmp/decoupledpatch.sh
cp devops/files/decoupled-README.md /tmp/decoupled-README.md

# Cherry-pick commits not modifying circle config onto the release branch
git checkout -b decoupled --track decoupled/main
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
  git cherry-pick -rn "$commit" 2>&1
  # Product request - single commit per release
  # The commit message from the last commit will be used.
  git log --format=%B -n 1 "$commit" > /tmp/commit_message
  # git commit --amend --no-edit --author='Pantheon Automation <bot@getpantheon.com>'
done

echo "Executing decoupledpatch.sh"
. /tmp/decoupledpatch.sh

echo "Copying README to docroot."
cp /tmp/decoupled-README.md ./README.md

git add .

echo "Committing changes"
git commit -F /tmp/commit_message --author='Pantheon Automation <bot@getpantheon.com>'

echo
echo "Releasing to upstream org"
echo

# Push to the decoupled repository
git push decoupled decoupled:main

git checkout $CIRCLE_BRANCH
