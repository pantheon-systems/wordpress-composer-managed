# Composer-enabled WordPress template

[![Early Access](https://img.shields.io/badge/Pantheon-Early%20Access-yellow?logo=pantheon&color=FFDC28)](https://pantheon.io/docs/oss-support-levels#early-access)

This is Pantheon's recommended starting point for forking new [WordPress](https://wordpress.org) upstreams that work with the Platform's Integrated Composer build process.

Unlike with other Pantheon upstreams, the WordPress core install, which you are unlikely to adjust while building sites, is not in the main branch of the repository. Instead, it is referenced as dependencies within [Roots/Bedrock](https://roots.io/bedrock/) that are installed by [Composer](https://getcomposer.org).

## Early Access software

A product in Early Access denotes a new project or feature set that is in development and available for a limited audience. Some features are stable, but the product is only partially complete and development is still in progress. For more information on support for Early Access projects, refer to our [documentation](https://pantheon.io/docs/guides/support/early-access/).

Want to participate in the Early Access program? [Fill out this request form.](https://docs.google.com/forms/d/e/1FAIpQLSe5WvxnzA7_U7B4clhhIYsPxI7DXkmQC-Y8J6pXmrbHYPzviw/viewform?usp=sf_link)

## Powered by Bedrock

<p align="left">
  <a href="https://roots.io/bedrock/">
    <img alt="Bedrock" src="https://cdn.roots.io/app/uploads/logo-bedrock.svg" height="50">
  </a>
</p>


[Bedrock](https://roots.io/bedrock/) is a modern WordPress stack that helps you get started with the best development tools and project structure.

Much of the philosophy behind Bedrock is inspired by the [Twelve-Factor App](http://12factor.net/) methodology including the [WordPress specific version](https://roots.io/twelve-factor-wordpress/).

## Features

- Better folder structure
- Dependency management with [Composer](https://getcomposer.org)
- Easy WordPress configuration with environment specific files
- Environment variables with [Dotenv](https://github.com/vlucas/phpdotenv)
- Autoloader for mu-plugins (use regular plugins as mu-plugins)
- Enhanced security (separated web root and secure passwords with [wp-password-bcrypt](https://github.com/roots/wp-password-bcrypt))

## How to use this project
There are two main ways to interact with this project template. **Using the Pantheon-maintained WordPress Composer Managed upstream** or **forking this repository to create a custom upstream.**

### Using the Pantheon WordPress Composer Managed upstream (recommended)

1. Use Terminus to create a site from the Pantheon upstream:
```
terminus site:create --org ORG --region REGION -- <site_name> <label> "WordPress (Composer Managed)"
```
1. In the Dev environment, click **Visit Development Site** and follow the prompts to complete the CMS installation.
2. [Clone the site locally](https://pantheon.io/docs/local-development#get-the-code) and run `composer install`.

### Fork this repository to create a custom upstream (advanced)

**Note:** It's highly recommended that you use the Pantheon-maintained upstream in favor of creating and managing a custom upstream so you can be sure to receive the latest updates. Managing your own custom upstream means that you assume ownership of the upstream and all changes made to it and assumes that you will manage all updates to the upstream.

1. Fork this repository into your own GitHub profile.
2. [Add a new Custom Upstream](https://pantheon.io/docs/guides/custom-upstream/create-custom-upstream#connect-repository-to-pantheon) on the Pantheon Dashboard.
3. Create a new WordPress site from the Upstream.

## Using Roots Bedrock

### Environment Variables

Bedrock makes use of an `.env` file to store environment variables. Pantheon takes care of many of these variabled in `.env.pantheon`. You may set your own environment variables in a new `.env` or environment variables that are local-only in `.env.local` using the `.env.example` as a guide. Wrap values that may contain non-alphanumeric characters with quotes, or they may be incorrectly parsed.

- Database variables
  - `DB_NAME` - Database name
  - `DB_USER` - Database user
  - `DB_PASSWORD` - Database password
  - `DB_HOST` - Database host
  - Optionally, you can define `DATABASE_URL` for using a DSN instead of using the variables above (e.g. `mysql://user:password@127.0.0.1:3306/db_name`)
- `WP_ENV` - Set to environment (`development`, `staging`, `production`)
- `WP_HOME` - Full URL to WordPress home (https://example.com)
- `WP_SITEURL` - Full URL to WordPress including subdirectory (https://example.com/wp)
- `AUTH_KEY`, `SECURE_AUTH_KEY`, `LOGGED_IN_KEY`, `NONCE_KEY`, `AUTH_SALT`, `SECURE_AUTH_SALT`, `LOGGED_IN_SALT`, `NONCE_SALT`
  - Generate with [wp-cli-dotenv-command](https://github.com/aaemnnosttv/wp-cli-dotenv-command)
  - Regenerate with [Bedrock's WordPress salts generator](https://roots.io/salts.html)

### WordPress Config

The `wp-config.php` file is located in the `web` directory. As with other WordPress sites on Pantheon, much of this is taken care of for you in `wp-config-pantheon.php`. Application-level configuration takes place in `config/application.php`. This can be referenced as a guide to understand how the constants are set up and how the `.env` files work, but modifying this file may result in merge conflicts and is not recommended. Any configuration changes should be made to your `wp-config.php` file directly.

You can learn more about WordPress configuration with Bedrock in the [Bedrock Configuration docs](https://docs.roots.io/bedrock/master/configuration/).

### Understanding the WordPress codebase

Bedrock installs WordPress as a required package so updates can be managed by Composer. As such, the contents of the `wp-content` directory have been moved outside the WordPress codebase so changes can be made safely to files within those directories without conflicts.

* Theme are installed into `web/app/themes/`.
* Plugins are installed into `web/app/plugins`.
* Must-use plugins are installed into `web/app/mu-plugins`.
* The WordPress admin dashboard is available at `https://example.com/wp/wp-admin/`

### Using Composer to manage plugins and themes

[Packagist](https://packagist.org) is a repository of Composer packages that are available by default to projects managed by Composer. Packagist libraries receive updates from their source GitHub repositories automatically.

[WPackagist](https://wpackagist.org) is a Packagist-like mirror of the WordPress.org [plugin](https://wordpress.org/plugins) and [theme](https://wordpress.org/themes) repositories and is included with Bedrock out of the box. 

You may install packages from Packagist or WPackagist without any additional configuration using `composer upstream-require`.

#### Requiring a package from Packagist

Some WordPress developers push their packages to Packagist in addition to the WordPress plugin and theme repositories. In this way, it may be beneficial to pull those packages directly from Packagist to get the latest code directly from the source.

```
composer upstream-require yoast/wordpress-seo
```

Packages that are flagged as `wordpress-plugin`, `wordpress-theme` or `wordpress-muplugin` in their `composer.json` files will be installed automatically in the appropriate `web/app/` directory by Composer.

#### Requiring a package from WPackagist

For all other plugins and themes that are not managed on Packagist, you can use `composer upstream-require` as well, using `wpackagist-plugin` or `wpackagist-theme` as the vendor and the plugin or theme slug as the package name.

```
composer upstream-require wpackagist-theme/twentytwentytwo
```

```
composer upstream-require wpackagist-plugin/advanced-custom-fields
```

## Contributing

Contributions are welcome in the form of GitHub pull requests. However, the `pantheon-upstreams/wordpress-composer-managed` repository is a mirror that does not directly accept pull requests.

Instead, to propose a change, please fork [pantheon-systems/wordpress-composer-managed](https://github.com/pantheon-systems/wordpress-composer-managed) and submit a PR to that repository.

## Community

There are large, thriving communities in both the Roots ecosystem and the Pantheon community that you can reach out to if you have any questions. 

- Join the [Pantheon Community Slack](https://join.slack.com/t/pantheon-community/shared_invite/zt-1e1reft3q-UXHfFovNWlUkBxodEkExBQ) and check out the #wordpress and #composer-workflow channels
- Join the Roots community on Discord by [sponsoring them on GitHub](https://github.com/sponsors/roots)
- Participate on the [Roots Discourse](https://discourse.roots.io/) or the [Pantheon Community Forums](https://discuss.pantheon.io/).
- Follow [@rootswp](https://twitter.com/rootswp) and [@getpantheon](https://twitter.com/getpantheon) on Twitter
