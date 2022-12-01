### 2022-11-30
* Set minimum-stability to "stable" in `composer.json` ([#55](https://github.com/pantheon-systems/wordpress-composer-managed/pull/55))
* Add Composer `post-install-cmd` to create symlinks to the `web/wp` directory (for better multisite support) ([#56](https://github.com/pantheon-systems/wordpress-composer-managed/pull/56))

### 2022-11-09
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

### 2022-10-17
* Load global .env file even if .env.local is absent ([#32](https://github.com/pantheon-systems/wordpress-composer-managed/pull/32))

### 2022-10-14
* Set permalink structure in build-env.install-cms Composer extra property ([#30](https://github.com/pantheon-systems/wordpress-composer-managed/pull/30))

### 2022-10-03
* Move Pantheon modifications in application.php ([#29](https://github.com/pantheon-systems/wordpress-composer-managed/pull/29))

### 2022-09-23
* `.gitignore` updates - Reported in the Pantheon Community Slack channel was the fact that the `.gitignore` included in this repository did not match the `.gitignore` (with commonly-ignored files) in the default [WordPress upstream](https://github.com/pantheon-systems/wordpress) ([#24](https://github.com/pantheon-systems/wordpress-composer-managed/pull/24))
* Use `.env.local` for local development ([#26](https://github.com/pantheon-systems/wordpress-composer-managed/pull/26)) - Fixes an issue where Lando was not using `.env` files locally.
* README updates ([#27](https://github.com/pantheon-systems/wordpress-composer-managed/pull/27) and [#28](https://github.com/pantheon-systems/wordpress-composer-managed/pull/28)) - Adds link to https://github.com/pantheon-upstreams/wordpress-composer-managed for forking, as well as additional guidance about the default branch name for custom upstreams.

### 2022-06-16
* Initial fork from [`roots/bedrock`](https://roots.io/bedrock) at 1.20.0. See the changelog prior to that at [`github.com/roots/bedrock`](https://github.com/roots/bedrock/blob/97f7826f3d284b82d83ff15d13bfc22628d660e2/CHANGELOG.md)
