<?php
/**
 * Pantheon platform settings.
 *
 * IMPORTANT NOTE:
 * Do not modify this file. This file is maintained by Pantheon.
 *
 * Site-specific modifications belong in wp-config.php, not this file. This
 * file may change in future releases and modifications would cause conflicts
 * when attempting to apply upstream updates.
 */

use Roots\WPConfig\Config;
use function Env\env;

/** A couple extra tweaks to help things run well on Pantheon. **/
if (isset($_SERVER['HTTP_HOST'])) {
    // HTTP is still the default scheme for now.
    $scheme = 'http';
    // If we have detected that the end use is HTTPS, make sure we pass that
    // through here, so <img> tags and the like don't generate mixed-mode
    // content warnings.
    if (isset($_SERVER['HTTP_USER_AGENT_HTTPS']) && $_SERVER['HTTP_USER_AGENT_HTTPS'] == 'ON') {
        $scheme = 'https';
        $_SERVER['HTTPS'] = 'on';
    }
    Config::define('WP_HOME', $scheme . '://' . $_SERVER['HTTP_HOST']);
    Config::define('WP_SITEURL', $scheme . '://' . $_SERVER['HTTP_HOST'] . '/wp');
}

// Don't show deprecations; useful under PHP 5.5
error_reporting(E_ALL ^ E_DEPRECATED);
/** Define appropriate location for default tmp directory on Pantheon */
define('WP_TEMP_DIR', sys_get_temp_dir());

/**
 * Set WP_ENVIRONMENT_TYPE according to the Pantheon Environment
 */
if (getenv('WP_ENVIRONMENT_TYPE') === false) {
    switch ($_ENV['PANTHEON_ENVIRONMENT']) {
        case 'live':
            putenv('WP_ENVIRONMENT_TYPE=production');
            break;
        case 'test':
            putenv('WP_ENVIRONMENT_TYPE=staging');
            break;
        default:
            putenv('WP_ENVIRONMENT_TYPE=development');
            break;
    }
}

/**
 * Force SSL
 */
if ( ! env('FORCE_SSL_ADMIN') ) {
    Config::define( 'FORCE_SSL_ADMIN', true );
}

/**
 * Defaults you may override
 *
 * To override, define your constant in your wp-config.php before wp-config-pantheon.php is required.
 */

/** Disable wp-cron.php from running on every page load and rely on Pantheon to run cron via wp-cli */
$network = isset($_ENV["FRAMEWORK"]) && $_ENV["FRAMEWORK"] === "wordpress_network";
if ( ! env( 'DISABLE_WP_CRON' ) && $network === false ) {
	Config::define('DISABLE_WP_CRON', true);
}