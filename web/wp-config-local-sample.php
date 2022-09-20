<?php
/**
 * This is a sample config for local development. wp-config.php will
 * load this file if you're not in a Pantheon environment. Simply edit/copy
 * as needed and rename to wp-config-local.php.
 *
 * Be sure to replace YOUR-LOCAL-DOMAIN below too.
 */

use Roots\WPConfig\Config;

$lando_home='http://YOUR-LOCAL-DOMAIN.lndo.site';
$lando_siteurl="$lando_home/wp";

Config::define('WP_HOME', $lando_home);
Config::define('WP_SITEURL', $lando_siteurl);

Config::apply();