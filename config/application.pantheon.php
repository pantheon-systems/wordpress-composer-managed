<?php
/**
 * Pantheon platform application settings.
 *
 * IMPORTANT NOTE:
 * Do not modify this file. This file is maintained by Pantheon.
 *
 * Site-specific modifications belong in config/application.php, not this file.
 * This file may change in future releases and modifications would cause
 * conflicts when attempting to apply upstream updates.
 */

use Roots\WPConfig\Config;
use function Env\env;

// Pantheon-specific settings.
if ( isset( $_ENV['PANTHEON_ENVIRONMENT'] ) ) {
	// These settings do not apply when using Lando local.
	if ( ! isset( $_ENV['LANDO'] ) ) {
		// Define appropriate location for default tmp directory on Pantheon.
		Config::define( 'WP_TEMP_DIR', sys_get_temp_dir() );

		// Set WP_ENVIRONMENT_TYPE according to the Pantheon Environment.
		if ( getenv( 'WP_ENVIRONMENT_TYPE' ) === false ) {
			switch ( $_ENV['PANTHEON_ENVIRONMENT'] ) {
				case 'live':
					putenv( 'WP_ENVIRONMENT_TYPE=production' );
					break;
				case 'test':
					putenv( 'WP_ENVIRONMENT_TYPE=staging' );
					break;
				default:
					putenv( 'WP_ENVIRONMENT_TYPE=development' );
					break;
			}
		}

		// We can use PANTHEON_SITE_NAME here because it's safe to assume we're on a Pantheon environment if PANTHEON_ENVIRONMENT is set.
		$sitename = $_ENV['PANTHEON_SITE_NAME'];
		$baseurl = $_ENV['PANTHEON_ENVIRONMENT'] . '-' . $sitename . '.pantheonsite.io';

		$scheme = 'http';
		if ( isset( $_SERVER['HTTPS'] ) && 'on' === $_SERVER['HTTPS'] ) {
			$scheme = 'https';
		}

		// Define the WP_HOME and WP_SITEURL constants if they aren't already defined.
		if ( ! env( 'WP_HOME' ) ) {
			// If HTTP_HOST is set, use that as the base URL. It's probably more accurate.
			if ( isset( $_SERVER['HTTP_HOST'] ) ) {
				$baseurl = $_SERVER['HTTP_HOST'];
			}

			$homeurl = $scheme . '://' . $baseurl;
			Config::define( 'WP_HOME', $homeurl );
			putenv( 'WP_HOME=' . $homeurl );

			if ( ! env( 'WP_SITEURL' ) ) {
				Config::define( 'WP_SITEURL', $homeurl . '/wp' );
				putenv( 'WP_SITEURL=' . $homeurl . '/wp' );
			}
		}

		/**
		 * Disable wp-cron.php from running on every page load and rely on Pantheon to run cron via wp-cli.
		 * We make an explicit exception here for multisite because there are cases where multisite does not work properly when WP_Cron is disabled.
		 * We only define DISABLE_WP_CRON if it's not already defined, which means you can override it in the application.php (though we don't recommend it).
		 */
		$network = isset( $_ENV['FRAMEWORK'] ) && $_ENV['FRAMEWORK'] === 'wordpress_network';
		if ( ! defined( 'DISABLE_WP_CRON' ) && ! env( 'DISABLE_WP_CRON' ) && $network === false ) {
			Config::define( 'DISABLE_WP_CRON', true );
		}
	}

	// Define PANTHEON_HOSTNAME.
	if ( ! defined( 'PANTHEON_HOSTNAME' ) ) {
		$site_name = $_ENV['PANTHEON_SITE_NAME'];
		$hostname = isset( $_SERVER['HTTP_HOST'] ) ? $_SERVER['HTTP_HOST'] : $_ENV['PANTHEON_ENVIRONMENT'] . "-{$site_name}.pantheonsite.io";
		$hostname = isset( $_ENV['LANDO'] ) ? "{$site_name}.lndo.site" : $hostname;
		define( 'PANTHEON_HOSTNAME', $hostname );
	}

	// Cookie settings.
	defined( 'COOKIE_DOMAIN' ) or Config::define( 'COOKIE_DOMAIN', PANTHEON_HOSTNAME );
	defined( 'ADMIN_COOKIE_PATH' ) or Config::define( 'ADMIN_COOKIE_PATH', '/' );
	defined( 'COOKIEPATH' ) or Config::define( 'COOKIEPATH', '/' );
	defined( 'SITECOOKIEPATH' ) or Config::define( 'SITECOOKIEPATH', '/' );
}
