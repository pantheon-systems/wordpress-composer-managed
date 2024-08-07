# Working with the WordPress (Composer Managed) upstream

## "Release" and "non-release" commits
The composer-managed upstreams (including Drupal (Composer Managed)) have a idiosyncratic concept of "release" or "normal" commits and "non-release" commits. **Release** commits are those that affect files that are ultimately pushed to the `pantheon-upstreams` repository. This includes everything that makes the base upstream work and _excludes_ any CI-related files, scripts or tests. **Non-release** commits are those that affect files that are not pushed to the `pantheon-upstreams` repository. This includes CI-related files, scripts, tests, and any other files that are not part of the base upstream.

Because we tend to prefer Squash merges on PRs rather than Merge commits, it is vital to separate interests and not combine _release_ and _non-release_ commits in the same PR. Doing so will lead to portions of the PR being dropped when the deploy script is run, leading to a mismatch between the `pantheon-systems` and `pantheon-upstreams` repositories. Multiple commits in a single PR that keep the division between _release_ and _non-release_ are allowed, **but should not be squash merged.**

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
 1. Commits modifying any of the following files and directories are omitted from `pantheon-upstreams`: `.circleci`, `devops`, `.github`. This prevents downstream Pantheon sites from being littered with our internal CI configuration, and allows us to enhance CI without generating irrelevant site updates. However, it means **you must not create commits that modify both automation and other files** in the same commit. 
 2. Commit authors appear on the dashboard. For this reason, they are rewritten to `Pantheon Automation <bot@getpantheon.com>` by automation.

## Automation demystified
The following workflows run on this repository:

### CircleCI
* There is only one CircleCI workflow, [`.circleci/config.yml`](.circleci/config.yml). This workflow runs on merge to `release` and handles the deployment of the new release to the `pantheon-upstreams` repositories. See the `devops` folder for the scripts that are run as part of this workflow.

### GitHub Actions
* `ci.yml` - This runs the `Lint and Test` job on pull requests. It runs on PHP 8.1-8.3 (Roots Bedrock does not support < PHP 8.1). Playwright tests are run in `playwright.yml` only after `ci.yml` determines that there are no linting issues. Additionally, `ci.yml` adds the commit checking workflow that is normally run on CircleCI to ensure that there are no non-release file changes mixed with release changes in a single commit. There are no tests configured in the upstream itself, so while `composer test` is run, it does not actually do anything.
* `composer-diff.yml` - This runs the `Composer Diff` job on pull requests. It compares the `composer.lock` file in the pull request to the `composer.lock` file in the `default` branch. If there are differences, it will comment on the pull request with the differences.
* `sage-test.yml` - This workflow only runs when changes have been made to any of the scripts in `private/scripts` (TODO: if we add more scripts to this directory, we might want to change this behavior to be more specific) or to the workflow file itself. It spins up a new multidev on the `wpcm-sage-install-tests` site on Pantheon and attempts to run `composer install-sage` script. The tests run on `ubuntu-latest` and `macos-latest` environments. (Windows environments need WSL2 to run the script which should broadly be covered by `ubuntu-latest`.)
* `sync-default.yml` - This workflow syncs the `default` branch to `main` in the `pantheon-systems/wordpress-composer-managed` repository. This is used for the [WordPress (Composer Managed) Nightly Canary](https://github.com/pantheon-systems/composer-managed-nightly-canaries). The canary is an automated workflow that spins up a brand new site on Pantheon off of the `default` branch of this repository and runs some basic tests to ensure that the site can be created and that the `composer install` script runs successfully. If the canary site fails to build, an update is posted to the `#cms-ecosystem-repos` channel in Slack.
* `playwright.yml` - This runs a suite of "hello world" style tests on fixture sites on the Pantheon platform using [Playwright](https://playwright.dev/). These tests were adapted from the [Composer Managed Nightly Canaries](https://github.com/pantheon-systems/composer-managed-nightly-canaries) tests originally developed by the Decoupled Kit team. The workflows set up new single site WordPress or subdirectory multisite WordPress sites using the Composer Managed upstream, copy files from the PR over to the new site, and install and run the Playwright tests. In the case of subdomain multisite, a single fixture site is maintained due to the complexity of setting up subdomains in automation.
* `phpcbf.yml` - This runs the `PHP Code Beautifier and Fixer` job on pull requests. It runs on all PRs, commits the changes back to the PR and adds a comment on the pull request if it changed anything. Note that `phpcbf` does not fix _all_ linting issues, and things that `phpcbf` cannot fix will still need to be fixed manually.

## Branch protections and their rationale

### In pantheon-systems
 1. The `default` branch does not accept merge commits. This is because this branch serves as the staging area for commits queued to be released to site upstreams, and the commit messages appear on customer dashboards as available updates. Preventing `Merged "[CORE-1234] Added widget to branch default [#62]"`-style commit messages enhances the user experience.

### In pantheon-upstreams
 1. All branches do not accept pushes, except by GitHub user `pantheon-circleci` and owners of the `pantheon-upstreams` organization, because GitHub hardcodes those users as able to push. This is just to avoid accidental direct pushes because commits to the upstreams repo are supposed to be made only from CircleCI as part of an intentional release with the commit authors rewritten.
