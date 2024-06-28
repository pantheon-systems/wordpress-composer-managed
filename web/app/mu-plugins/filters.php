<?php
/**
 * Plugin Name: Pantheon WordPress Filters
 * Plugin URI:   https://github.com/pantheon-systems/wordpress-composer-managed
 * Description:  Filters for Composer-managed WordPress sites on Pantheon.
 * Version:      1.1.0
 * Author:       Pantheon Systems
 * Author URI:   https://pantheon.io/
 * License:      MIT License
 */

namespace Pantheon\WordPressComposerManaged\Filters;

/**
 * Update the multisite configuration to use Config::define() instead of define.
 *
 * @return string
 */
add_filter( 'pantheon.multisite.config_contents', function ( $config_contents ) {
	$config_contents = str_replace( 'define(', 'Config::define(', $config_contents );
	return $config_contents;
} );

/**
 * Update the wp-config filename to use config/application.php.
 *
 * @return string
 */
add_filter( 'pantheon.multisite.config_filename', function ( $config_filename ) {
	return 'config/application.php';
} );

/**
 * Correct core resource URLs for non-main sites in a subdirectory multisite network.
 *
 * @param string $url The URL to fix.
 * @return string The fixed URL.
 */
function fix_core_resource_urls( string $url ) : string {
	$main_site_url = trailingslashit( network_site_url( '/' ) );
	$current_site_path = trailingslashit( get_blog_details()->path );

	// Parse the URL to get its components.
	$parsed_url = parse_url( $url );

	// If there is no path in the URL, return it as is.
	if ( ! isset( $parsed_url['path'] ) || $parsed_url['path'] === '/' ) {
		return $url;
	}

	$path = $parsed_url['path'];
	$core_paths = [ 'wp-includes/', 'wp-admin/', 'wp-content/' ];
	$path_modified = false;

	foreach ( $core_paths as $core_path ) {
		if ( strpos( $path, $current_site_path . $core_path ) !== false ) {
			$path = str_replace( $current_site_path . $core_path, $core_path, $path );
			$path_modified = true;
			break;
		}
	}

	// If the path was not modified, return the original URL.
	if ( ! $path_modified ) {
		return $url;
	}

	// Prepend the main site URL to the modified path.
	$new_url = $main_site_url . ltrim( $path, '/' );

	// Append any query strings if they existed in the original URL.
	if ( isset( $parsed_url['query'] ) ) {
		$new_url .= '?' . $parsed_url['query'];
	}

	return $new_url;
}

// Only run the filter on non-main sites in a subdirectory multisite network.
if ( is_multisite() && ! is_subdomain_install() && ! is_main_site() ) {
	$filters = [
		'script_loader_src',
		'style_loader_src',
		'plugins_url',
		'theme_file_uri',
		'stylesheet_directory_uri',
		'template_directory_uri',
		'site_url',
		'content_url'
	];
	foreach ( $filters as $filter ) {
		add_filter( $filter, __NAMESPACE__ . '\\fix_core_resource_urls', 9 );
	}
}

/**
 * Drop the /wp, if it exists, from URLs on the main site (single site or multisite).
 *
 * is_main_site will return true if the site is not multisite.
 *
 * @param string $url The URL to check.
 *
 * @return string The filtered URL.
 */
function adjust_main_site_urls( string $url ) : string {
	// If this is the main site, drop the /wp.
	if ( is_main_site() && ! __is_login_url( $url ) ) {
		$url = str_replace( '/wp/', '/', $url );
	}

	return $url;
}
add_filter( 'home_url', __NAMESPACE__ . '\\adjust_main_site_urls', 9 );
add_filter( 'site_url', __NAMESPACE__ . '\\adjust_main_site_urls', 9 );

function __is_login_url( string $url ) : bool {
	$is_login_url = false;

	// Validate that the string passed was actually a URL.
	if ( ! preg_match( '/^https?:\/\//i', $url ) ) {
		$url = 'http://' . ltrim( $url, '/' );
	}

	// Bail if the string is not a valid URL.
	if ( ! wp_http_validate_url( $url ) ) {
		return $is_login_url;
	}

	// Login page?
	if ( strpos( $url, 'wp-login' ) !== false ) {
		$is_login_url = true;
	}

	// Admin page?
	if ( strpos( $url, 'wp-admin' ) !== false ) {
		$is_login_url = true;
	}

	return $is_login_url;
}

function __normalize_wp_url( string $url ) : string {
	$scheme_end_pos = strpos( $url, '://' );

	// Extract the scheme from the URL.
	if ( $scheme_end_pos !== false ) {
		$scheme = substr( $url, 0, $scheme_end_pos + 3 );
		$remaining_url = substr( $url, $scheme_end_pos + 3 );
	} else {
		$scheme = '';
		$remaining_url = $url;
	}

	// Normalize the URL to remove any double slashes.
	$url = str_replace( '//', '/', $remaining_url );
	return $scheme . $url;
}
