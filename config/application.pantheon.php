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

if ( isset( $_ENV['PANTHEON_ENVIRONMENT'] ) ) {
	if ( ! isset( $_ENV['LANDO'] ) ) {
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
	}

	if ( ! defined( 'PANTHEON_HOSTNAME' ) ) {
		$site_name = $_ENV['PANTHEON_SITE_NAME'];
		$hostname = isset( $_SERVER['HTTP_HOST'] ) ? $_SERVER['HTTP_HOST'] : $_ENV['PANTHEON_ENVIRONMENT'] . "-{$site_name}.pantheonsite.io";
		$hostname = isset( $_ENV['LANDO'] ) ? "{$site_name}.lndo.site" : $hostname;
		define( 'PANTHEON_HOSTNAME', $hostname );
	}
}
