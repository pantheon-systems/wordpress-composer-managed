# Working with the WordPress (Composer Managed) upstream

## Cutting a new release
 1. Update CHANGELOG.md. In the past, the copy has been created in consultation with the product owner.
 1. Ensure the commit message for the last commit in this release says what we want to have appearing on the
    dashboard as an available update. See [CORE-2258](https://getpantheon.atlassian.net/browse/CORE-2258) for
    the inaugural example of such a commit message. All changes are committed to `pantheon-upstreams` as a single
    commit, and the message that is used for it is the one from the last commit.
    * Typically the CHANGELOG.md commit is the last one and so is the one whose commit message should be wordsmithed.
 1. Trigger the new release to `pantheon-upstreams` by `--ff-only`-merging `default` into `release` and pushing the 
    result:
    ```
    git fetch
    git checkout release && git pull
    git merge --ff-only origin/default
    git push origin release
    ```
    A CircleCI job causes the release to be created.

## Preventing `composer.lock` from being committed

Committing `composer.lock` to the upstream repository will break downstream sites using integrated Composer. To prevent this from happening, after cloning this repository, you can add `composer.lock` to the `.git/info/exclude` in your local copy. Note that this needs to be done for any local copies you wish to apply this rule to.

## Development and release procedures

There are some atypical development and release procedures in use with this repository:
 1. The currently released version of this repository lives in parallel in the `main` branch of [pantheon-upstreams/wordpress-composer-managed](https://github.com/pantheon-upstreams/wordpress-composer-managed). `pantheon-upstreams/wordpress-composer-managed` closely mirrors the development repository at [pantheon-systems/wordpress-composer-managed](https://github.com/pantheon-systems/wordpress-composer-managed) and is updated by CircleCI automation.
 1. Changes are made by submitting a PR against the `default` branch of `pantheon-systems/wordpress-composer-managed`.
 1. Merging a PR to `default` _does not_ create a new release of `pantheon-upstreams/wordpress-composer-managed`. This allows us to batch more than one relatively small change into a single new "release" such that the number of separate update events appearing on customer dashboards is more controlled.

### Differences between `pantheon-upstreams` and `pantheon-systems` repos:
 1. Commits modifying any of the following files and directories are omitted from `pantheon-upstreams`: `.circleci`, `devops`, `.github`, `README-internal.md`. This prevents downstream Pantheon sites from being littered with our internal CI configuration, and allows us to enhance CI without generating irrelevant site updates. However, it means **you must not create commits that modify both automation and other files** in the same commit. For this reason **squash commits are discouraged** (as they can contain changes to multiple files).
 2. Commit authors appear on the dashboard. For this reason, they are rewritten to `Pantheon Automation <bot@getpantheon.com>`.

## Automation demystified
The following workflows run on this repository:

### CircleCI
* There is only one CircleCI workflow, [`.circleci/config.yml`](.circleci/config.yml). This workflow runs on merge to `release` and handles the deployment of the new release to the `pantheon-upstreams` repositories. See the `devops` folder for the scripts that are run as part of this workflow.

### GitHub Actions
* `ci.yml` - This runs the `Lint and Test` job on pull requests. It runs on PHP 8.x (Roots Bedrock does not support < PHP 8). There are no tests configured, so while `composer test` is run, it does not actually do anything.
* `composer-diff.yml` - This runs the `Composer Diff` job on pull requests. It compares the `composer.lock` file in the pull request to the `composer.lock` file in the `default` branch. If there are differences, it will comment on the pull request with the differences.
* `sage-test.yml` - This workflow only runs when changes have been made to any of the scripts in `private/scripts` (TODO: if we add more scripts to this directory, we might want to change this behavior to be more specific) or to the workflow file itself. It spins up a new multidev on the `wpcm-sage-install-tests` site on Pantheon and attempts to run `composer install-sage` script. The tests run on `ubuntu-latest` and `macos-latest` environments. (Windows environments need WSL2 to run the script which should broadly be covered by `ubuntu-latest`.)
* `sync-default.yml` - This workflow syncs the `default` branch to `main` in the `pantheon-systems/wordpress-composer-managed` repository. This is used for the [WordPress (Composer Managed) Nightly Canary](https://github.com/pantheon-systems/composer-managed-nightly-canaries). The canary is an automated workflow that spins up a brand new site on Pantheon off of the `default` branch of this repository and runs some basic tests to ensure that the site can be created and that the `composer install` script runs successfully. If the canary site fails to build, an update is posted to the `#cms-ecosystem-repos` channel in Slack.

## Branch protections and their rationale

### In pantheon-systems
 1. The `default` branch does not accept merge commits. This is because this branch serves as the staging area for commits queued to be released to site upstreams, and the commit messages appear on customer dashboards as available updates. Preventing `Merged "[CORE-1234] Added widget to branch default [#62]"`-style commit messages enhances the user experience.

### In pantheon-upstreams
 1. All branches do not accept pushes, except by GitHub user `pantheon-circleci` and owners of the `pantheon-upstreams` organization, because GitHub hardcodes those users as able to push. This is just to avoid accidental direct pushes because commits to the upstreams repo are supposed to be made only from CircleCI as part of an intentional release with the commit authors rewritten.
