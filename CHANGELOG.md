### v1.32.0 (2024-08-06)
* This update primarily fixes consistency issues between the development repository ([`pantheon-systems/wordpress-composer-managed`](https://github.com/pantheon-systems/wordpress-composer-managed)) and the upstream repository ([`pantheon-upstreams/wordpress-composer-managed`](https://github.com/pantheon-upstreams/wordpress-composer-managed)). Most notably, this update removes decoupled packages that were erroneously being added to the non-decoupled upstream (and are not included in this repository).
* Fixes issues with subdomain multisite testing ([#148](https://github.com/pantheon-systems/wordpress-composer-managed/pull/148))
* Updates automation steps to check PRs for "mixed" commits ([#146](https://github.com/pantheon-systems/wordpress-composer-managed/pull/146)) and adds handling for merge commits and conflicts ([#152](https://github.com/pantheon-systems/wordpress-composer-managed/pull/152))
* Moves cookie settings inside the pantheon environment check ([#151](https://github.com/pantheon-systems/wordpress-composer-managed/pull/151))

### v1.31.1 (2024-07-29)
* Removes code that for handling wp-admin URLs. ([#143](https://github.com/pantheon-systems/wordpress-composer-managed/pull/143)) This code was not working as intended and testing revealed it to be unnecessary.
* Adds a filter to disable the subdirectory multisite custom wp-content directory warning. ([#144](https://github.com/pantheon-systems/wordpress-composer-managed/pull/144)) This implements the filter added in the [Pantheon MU Plugin](https://github.com/pantheon-systems/pantheon-mu-plugin) in [#51](https://github.com/pantheon-systems/pantheon-mu-plugin/pull/51).

### v1.31.0 (2024-07-10)
* `wp-config-pantheon.php` deprecated in favor of `application.pantheon.php`. All previous functionality in `wp-config-pantheon.php` moved to `application.pantheon.php`. ([#139](https://github.com/pantheon-systems/wordpress-composer-managed/pull/139))
* `DISABLE_WP_CRON` constant removed from `application.php` (and `wp-config-pantheon.php`) and moved to `application.pantheon.php`. ([#139](https://github.com/pantheon-systems/wordpress-composer-managed/pull/139)) It's possible this change could cause a merge conflict. Accept incoming changes from the upstream or [resolve manually](https://docs.pantheon.io/guides/git/resolve-merge-conflicts).
* Cookie domain handling in `application.pantheon.php` to resolve cookie-related login redirect issues on subdomain multisites. ([#137](https://github.com/pantheon-systems/wordpress-composer-managed/pull/137))
* Updates to `application.php` and `composer.json` to bring WordPress (Composer Managed) in line with [`roots/bedrock`](https://github.com/roots/bedrock) v1.24.x. ([#134](https://github.com/pantheon-systems/wordpress-composer-managed/pull/134))
* Correct WordPress site urls on main sites or single sites to drop the `/wp` in WordPress-generated home links. ([#132](https://github.com/pantheon-systems/wordpress-composer-managed/pull/132)) This fixes an issue where WordPress-generated links to the primary site always included an unnecessary trailing `/wp`. This is handled by a filter in `mu-plugins/filters.php` set to priority `9` so it can be easily overridden.
* Pre-set the WP GraphQL endpoint path to `wp/graphql` if the plugin exists to preserve existing functionality after URL filters above. ([#138](https://github.com/pantheon-systems/wordpress-composer-managed/pull/138))
* Bump PHP version to 8.2 and DB version to 10.6. ([#133](https://github.com/pantheon-systems/wordpress-composer-managed/pull/133)) PHP back to 8.1 is still supported but PHP 8.0 support is dropped by the Composer configuration to follow current Bedrock and Sage minimum requirements.
* Update the `update_php` function in `helpers.sh` to update PHP version in `pantheon.yml` to 8.1 (or higher) to follow new Bedrock and Sage PHP minimum. ([#131](https://github.com/pantheon-systems/wordpress-composer-managed/pull/131))
* Silences the check for multisite in the Sage theme install script. ([#131](https://github.com/pantheon-systems/wordpress-composer-managed/pull/131)) Previously a warning would be shown if the site the script was being run against was not a multisite because the `MULTISITE` constant did not exist.
* Adds a check to see if the generated Sage theme exists prior to theme activation. ([#131](https://github.com/pantheon-systems/wordpress-composer-managed/pull/131)) This change corrects the script's behavior to not attempt to activate the theme if it does not exist.
* Ensure managed WordPress files aren't omitted. ([#128](https://github.com/pantheon-systems/wordpress-composer-managed/pull/128)) This fixes an issue where some required files were being ignored by version control. Props [@araphiel](https://github.com/araphiel)
* Filters core resource URLs for non-main sites in subdirectory multisites. ([#130](https://github.com/pantheon-systems/wordpress-composer-managed/pull/130)) This fixes an issue where core resource URLs (e.g. to WordPress core JavaScript and CSS assets) were linked incorrectly in subdirectory subsites. This is handled by a filter in `mu-plugins/filters.php` set to priority `9` so it can be easily overridden.
* Replace `tput` with a `save_tput` function in `helpers.sh`. ([#129](https://github.com/pantheon-systems/wordpress-composer-managed/pull/129)) This fixes an issue where a warning was being displayed in Workflow Logs in the dashboard because the `tput` function was not available in the terminal environment.
* Adds semver versioning convention to CHANGELOG to track changes easier. (Tags will begin at 1.31.0 rather than retroactively creating new tags.)
* Adds `package.json` file and [Playwright](https://playwright.dev/) tests for functional testing. ([#138](https://github.com/pantheon-systems/wordpress-composer-managed/pull/138))

### v1.30.0 (2024-06-04)
* Filters the configuration file filename on the Setup Network instructions page to use `config/application.php` instead of `wp-config.php`. ([#125](https://github.com/pantheon-systems/wordpress-composer-managed/pull/125))
* Adds Composer script to update the `platform.php` value to the version of PHP consistent with the version in the `pantheon.yml` file. ([#127](https://github.com/pantheon-systems/wordpress-composer-managed/pull/127)

### v1.29.0 (2024-04-30)
* Adds a new `PANTHEON_HOSTNAME` constant to `application.pantheon.php` to be used for configuring multisites. For more information, see our [mulstisite configuration documentation](https://docs.pantheon.io/guides/multisite/config). ([#119](https://github.com/pantheon-systems/wordpress-composer-managed/pull/119))
* Implements `pantheon.multisite.config_contents` filter to correct the multisite configuration instructions (to use `Config::define` instead of `define`).
* Adds a new `filters.php` mu-plugin for the `pantheon.multisite.config_contents` filter and any future filters we might add.
* Adds `lint:phpcbf` script to the `composer.json`.

### v1.28.2 (2024-04-15)
* Fixed an issue where `WP_HOME` was left undefined and throwing notices into New Relic logs. For more information, see our [release note](https://docs.pantheon.io/release-notes/2024/04/wordpress-composer-managed-update). ([#115](https://github.com/pantheon-systems/wordpress-composer-managed/pull/115))

### v1.28.1 (2023-09-25)
* Updates to the [Sage install script](docs/Installing-Sage.md) to support running the script without prompting for input. Also adds automated test runs of the script on `ubuntu-latest` and `macos-latest` environments. ([#113](https://github.com/pantheon-systems/wordpress-composer-managed/pull/113))

### v1.28.0 (2023-06-27)
* Fixed a bug that failed to prevent a `composer.lock` file from being committed to the repository. ([#103](https://github.com/pantheon-systems/wordpress-composer-managed/pull/103))
* Removed the `upstream-require` script ([#105](https://github.com/pantheon-systems/wordpress-composer-managed/pull/105)). This is now available as a standalone Composer plugin: [`pantheon-systems/upstream-management`](https://packagist.org/packages/pantheon-systems/upstream-management)
* Added a README to the Upstream Configuration path repository with notes about the new `upstream-management` package. ([#104](https://github.com/pantheon-systems/wordpress-composer-managed/pull/104))

### v1.27.0 (2023-05-23)
* Removes the `lh-hsts` plugin requirement from the `composer.json` file. ([#91](https://github.com/pantheon-systems/wordpress-composer-managed/pull/91))
* Adds the [Pantheon WP Coding Standards](https://github.com/pantheon-systems/pantheon-wp-coding-standards) to use instead of the default PHPCS/WPCS standards ([#94](https://github.com/pantheon-systems/wordpress-composer-managed/pull/94))
* Backports updates from Roots/Bedrock ([#90](https://github.com/pantheon-systems/wordpress-composer-managed/pull/90))
* Updates the `post-install-cmd` hook to run a script that checks for the existence of symlinks before attempting to create them. ([#98](https://github.com/pantheon-systems/wordpress-composer-managed/pull/98))
* Minor improvements to the Sage install process (included in [#98](https://github.com/pantheon-systems/wordpress-composer-managed/pull/98))

### v1.26.0 (2023-03-29)
* Changes the language in comments about appropriate usage of `config/application.php`. `application.php` should be used for any site config customizations rather than `wp-config.php` which should _not_ be edited. ([#76](https://github.com/pantheon-systems/wordpress-composer-managed/pull/76))
* Updates the Sage install script to properly update the PHP version. ([#81](https://github.com/pantheon-systems/wordpress-composer-managed/pull/81))
* Updates the Sage install script to force symbolic links rather than attepting to create them on each `composer install`. ([#79](https://github.com/pantheon-systems/wordpress-composer-managed/pull/79))
* Updates the Sage install script to attempt to fix invalid theme names. ([#80](https://github.com/pantheon-systems/wordpress-composer-managed/pull/80))
* Updates the Sage install script to fail hard if `jq` is not found, but provide links to download the executable. ([#82](https://github.com/pantheon-systems/wordpress-composer-managed/pull/82))
* Fixes an issue that led to failing builds due to an unstaged `index.php` file created by the forced symlinks. ([#86](https://github.com/pantheon-systems/wordpress-composer-managed/pull/86))

### v1.25.0 (2023-02-02)
* Adds Composer Patches plugin ([#66](https://github.com/pantheon-systems/wordpress-composer-managed/pull/66))

### v1.24.0 (2023-01-11)
* Remove Dependabot ([#58](https://github.com/pantheon-systems/wordpress-composer-managed/pull/58))
* Resolves issue where updates to commit choosing logic were causing a merge conflict. ([#60](https://github.com/pantheon-systems/wordpress-composer-managed/pull/60))
* Adds a Roots Sage install script. See [docs/Installing-Sage.md](docs/Installing-Sage.md) ([#61](https://github.com/pantheon-systems/wordpress-composer-managed/pull/61))

### v1.23.1 (2022-11-30)
* Set minimum-stability to "stable" in `composer.json` ([#55](https://github.com/pantheon-systems/wordpress-composer-managed/pull/55))
* Add Composer `post-install-cmd` to create symlinks to the `web/wp` directory (for better multisite support) ([#56](https://github.com/pantheon-systems/wordpress-composer-managed/pull/56))

### v1.23.0 (2022-11-09)
* Pull the latest versions of all packages ([#36](https://github.com/pantheon-systems/wordpress-composer-managed/pull/36))
* Improved debug log path suggested in `.env.example` ([#38](https://github.com/pantheon-systems/wordpress-composer-managed/pull/38))
* Get latest WP updates (and other WP-related dependencies) automatically ([#40](https://github.com/pantheon-systems/wordpress-composer-managed/pull/40))
* Always pull the latest Pantheon plugins from wpackagist ([#45](https://github.com/pantheon-systems/wordpress-composer-managed/pull/45))
* Change from `php_version` to `php-version` in testing matrix ([#46](https://github.com/pantheon-systems/wordpress-composer-managed/pull/46))
* Additional Lando configuration ([#47](https://github.com/pantheon-systems/wordpress-composer-managed/pull/47))
* Fix a typo in `README-internal.md` ([#48](https://github.com/pantheon-systems/wordpress-composer-managed/pull/48))
* Exclude `.github/` from the deploy script for the upstream repository. ([#50](https://github.com/pantheon-systems/wordpress-composer-managed/pull/50))
* Also forbid `.github/workflows/ci.yml` from the deploy script. ([#51](https://github.com/pantheon-systems/wordpress-composer-managed/pull/51))
* Skip commits in deploy process for nonrelease changes ([#52](https://github.com/pantheon-systems/wordpress-composer-managed/pull/52) [#53](https://github.com/pantheon-systems/wordpress-composer-managed/pull/53))

### v1.22.2 (2022-10-17)
* Load global .env file even if .env.local is absent ([#32](https://github.com/pantheon-systems/wordpress-composer-managed/pull/32))

### v1.22.1 (2022-10-14)
* Set permalink structure in build-env.install-cms Composer extra property ([#30](https://github.com/pantheon-systems/wordpress-composer-managed/pull/30))

### v1.22.0 (2022-10-03)
* Move Pantheon modifications in application.php ([#29](https://github.com/pantheon-systems/wordpress-composer-managed/pull/29))

### v1.21.0 (2022-09-23)
* `.gitignore` updates - Reported in the Pantheon Community Slack channel was the fact that the `.gitignore` included in this repository did not match the `.gitignore` (with commonly-ignored files) in the default [WordPress upstream](https://github.com/pantheon-systems/wordpress) ([#24](https://github.com/pantheon-systems/wordpress-composer-managed/pull/24))
* Use `.env.local` for local development ([#26](https://github.com/pantheon-systems/wordpress-composer-managed/pull/26)) - Fixes an issue where Lando was not using `.env` files locally.
* README updates ([#27](https://github.com/pantheon-systems/wordpress-composer-managed/pull/27) and [#28](https://github.com/pantheon-systems/wordpress-composer-managed/pull/28)) - Adds link to https://github.com/pantheon-upstreams/wordpress-composer-managed for forking, as well as additional guidance about the default branch name for custom upstreams.

### v1.20.0 (2022-06-16)
* Initial fork from [`roots/bedrock`](https://roots.io/bedrock) at 1.20.0. See the changelog prior to that at [`github.com/roots/bedrock`](https://github.com/roots/bedrock/blob/97f7826f3d284b82d83ff15d13bfc22628d660e2/CHANGELOG.md)
