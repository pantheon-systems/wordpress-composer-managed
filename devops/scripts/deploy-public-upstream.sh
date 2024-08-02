#!/bin/bash
# This script is pretty tailored to assuming it's running in the CircleCI environment / a fresh git clone.
# It mirrors most commits from `pantheon-systems/wordpress-composer-managed:release` to `pantheon-upstreams/wordpress-composer-managed`.

# Check github authentication; ignore status code 1 returned from this command
ssh -T git@github.com

# Fail fast on any future errors.
set -euo pipefail

. devops/scripts/commit-type.sh

# Copy README file to tmp directory for use after checkout.
echo "Copying composer-managed-README to /tmp for use later."
cp devops/files/composer-managed-README.md /tmp/composer-managed-README.md

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
    commits+=("$commit")
    continue
  fi

  if [[ $commit_type == "mixed" ]] ; then
    2>&1 echo "Commit ${commit} contains both release and nonrelease changes. Skipping this commit."
    echo "You may wish to ensure that nothing in this commit is meant for release."
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
  if ! git cherry-pick -rn -X theirs -m 1 "$commit"; then
    echo "Conflict detected in $commit. Checking for deleted files."
    conflicted_files=$(git diff --name-only --diff-filter=U)
    for file in $conflicted_files; do
      if ! git ls-tree -r "$commit" --name-only | grep -q "^$file$"; then
        echo "File $file was deleted in the cherry-picked commit. Resolving by keeping the deletion."
        git rm "$file"
      else
        echo "Conflict required manual resolution for $file."
      fi
    done

    # Stage the changes and continue the cherry-pick
    git add -u
    git commit --no-edit || {
      echo "No changes to commit. Continuing."
    }
  fi
  # Product request - single commit per release
  # The commit message from the last commit will be used.
  git log --format=%B -n 1 "$commit" > /tmp/commit_message
done

echo "Copying README to docroot."
rm ./README.md
cp /tmp/composer-managed-README.md ./README.md

# Create a list of files that we need to exclude from the commit.
# These are files that may be coming from Roots or old commits that do not exist in the source and _should not exist_ on the upstream.
ignored_files="composer.lock CODE_OF_CONDUCT.md CONTRIBUTING.md"

# Remove ignored files from the commit.
for file in $ignored_files; do
  if [ -f "$file" ]; then
    echo "Removing $file from the commit."
    git rm "$file"
  fi
done

git add .

echo "Committing changes"
git commit -F /tmp/commit_message --author='Pantheon Automation <bot@getpantheon.com>'

echo
echo "Releasing to upstream org"
echo

# Push to the public repository
git push public public:main

git checkout "$CIRCLE_BRANCH"

# update the release-pointer
git tag -f -m 'Last commit set on upstream repo' release-pointer HEAD

# Push release-pointer
git push -f origin release-pointer
