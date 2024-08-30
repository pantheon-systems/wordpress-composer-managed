<?php
/**
 * Plugin Name: Pantheon WordPress Filters
 * Plugin URI:   https://github.com/pantheon-systems/wordpress-composer-managed
 * Description:  Filters for Composer-managed WordPress sites on Pantheon.
 * Version:      1.2.2
 * Author:       Pantheon Systems
 * Author URI:   https://pantheon.io/
 * License:      MIT License
 */

namespace Pantheon\WordPressComposerManaged\Filters;

/**
 * Update the multisite configuration to use Config::define() instead of define.
 *
 * @since 1.0.0
 * @return string
 */
add_filter( 'pantheon.multisite.config_contents', function ( $config_contents ) {
	$config_contents = str_replace( 'define(', 'Config::define(', $config_contents );
	return $config_contents;
} );

/**
 * Update the wp-config filename to use config/application.php.
 *
 * @since 1.0.0
 * @return string
 */
add_filter( 'pantheon.multisite.config_filename', function ( $config_filename ) {
	return 'config/application.php';
} );

/**
 * Disable the subdirectory networks custom wp-content directory warning.
 *
 * @since 1.2.0
 * @return bool Default true. We set false to disable the warning.
 */
add_filter( 'pantheon.enable_subdirectory_networks_message', '__return_false' );

/**
 * Correct core resource URLs for non-main sites in a subdirectory multisite network.
 *
 * @since 1.1.0
 * @param string $url The URL to fix.
 * @return string The fixed URL.
 */
function fix_core_resource_urls( string $url ) : string {
	global $current_blog;
	$main_site_url = trailingslashit( is_multisite() ? network_site_url( '/' ) : home_url() );

	// Get the current site path. Covers a variety of scenarios since we're using this function on a bunch of different filters.
	$current_site_path = trailingslashit( parse_url( get_home_url(), PHP_URL_PATH ) ); // Define a default path.
	if ( is_multisite() ) {
		if ( isset( $current_blog ) && ! empty( $current_blog->path ) ) {
			$current_site_path = trailingslashit( $current_blog->path );
		} elseif ( function_exists( 'get_blog_details' ) ) {
			$current_site_path = trailingslashit( get_blog_details()->path );
		}
	}

	// Parse the URL to get its components.
	$parsed_url = parse_url( $url );

	// If there is no path in the URL, return it as is.
	if ( ! isset( $parsed_url['path'] ) || $parsed_url['path'] === '/' ) {
		return $url;
	}

	$path = $parsed_url['path'];
	$core_paths = [ '/wp-includes/', '/wp-content/' ];
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

	return __normalize_wp_url( $new_url );
}

/**
 * Filters to run fix_core_resource_urls on to fix the core resource URLs.
 *
 * @since 1.2.1
 * @see fix_core_resource_urls
 */
function filter_core_resource_urls() {
	$filters = [
		'script_loader_src',
		'style_loader_src',
		'plugins_url',
		'theme_file_uri',
		'stylesheet_directory_uri',
		'template_directory_uri',
		'site_url',
		'content_url',
	];
	foreach ( $filters as $filter ) {
		add_filter( $filter, __NAMESPACE__ . '\\fix_core_resource_urls', 9 );
	}
}
add_action( 'init', __NAMESPACE__ . '\\filter_core_resource_urls' );

/**
 * Prepopulate GraphQL endpoint URL with default value if unset.
 * This will ensure that the URL is not changed from /wp/graphql to /graphql by our other filtering unless that's what the user wants.
 *
 * @since 1.1.0
 */
function prepopulate_graphql_endpoint_url() {
	$options = get_option( 'graphql_general_settings' );

	// Bail early if options have already been set.
	if ( $options ) {
		return;
	}

	$options = [];
	$site_path = site_url();
	$endpoint = ( ! empty( $site_path ) || strpos( $site_path, 'wp' ) !== false ) ? 'graphql' : 'wp/graphql';
	$options['graphql_endpoint'] = $endpoint;
	update_option( 'graphql_general_settings', $options );
}
add_action( 'graphql_init', __NAMESPACE__ . '\\prepopulate_graphql_endpoint_url' );

/**
 * Drop the /wp, if it exists, from URLs on the main site (single site or multisite).
 *
 * is_main_site will return true if the site is not multisite.
 *
 * @since 1.1.0
 * @param string $url The URL to check.
 * @return string The filtered URL.
 */
function adjust_main_site_urls( string $url ) : string {
	if ( doing_action( 'graphql_init' ) || __is_login_url( $url ) ) {
		return $url;
	}

	// Explicit handling for /wp/graphql
	if ( strpos( $url, '/graphql' ) !== false ) {
		return $url;
	}

	// If this is the main site, drop the /wp.
	if ( is_main_site() && is_multisite() ) {
		$url = str_replace( '/wp/', '/', $url );
	}

	return $url;
}
add_filter( 'home_url', __NAMESPACE__ . '\\adjust_main_site_urls', 9 );
add_filter( 'site_url', __NAMESPACE__ . '\\adjust_main_site_urls', 9 );

/**
 * Check the URL to see if it's either an admin or wp-login URL.
 *
 * Validates that the URL is actually a URL before checking.
 *
 * @since 1.1.0
 * @param string $url The URL to check.
 * @return bool True if the URL is a login or admin URL. False if it's not or is not actually a URL.
 */
function __is_login_url( string $url ) : bool {
	// Validate that the string passed was actually a URL.
	if ( ! preg_match( '/^https?:\/\//i', $url ) ) {
		$url = 'http://' . ltrim( $url, '/' );
	}

	// Bail if the string is not a valid URL.
	if ( ! wp_http_validate_url( $url ) ) {
		return false;
	}

	// Check if the URL is a login or admin page
	if ( strpos( $url, 'wp-login' ) !== false || strpos($url, 'wp-admin' ) !== false) {
		return true;
	}

	return false;
}

/**
 * Remove double-slashes (that aren't http/https://) from URLs.
 *
 * @since 1.1.0
 * @param string $url The URL to test.
 * @return string The normalized URL.
 */
function __normalize_wp_url( string $url ): string {
	// Parse the URL into components.
	$parts = parse_url( $url );

	// Normalize the URL to remove any double slashes.
	if ( isset( $parts['path'] ) ) {
		$parts['path'] = preg_replace( '#/+#', '/', $parts['path'] );
	}

	// Rebuild and return the full normalized URL.
	return __rebuild_url_from_parts( $parts );
}

/**
 * Rebuild parsed URL from parts.
 *
 * @since 1.1.0
 * @param array $parts URL parts from parse_url.
 * @return string Re-parsed URL.
 */
function __rebuild_url_from_parts( array $parts ) : string {
	return trailingslashit(
		( isset( $parts['scheme'] ) ? "{$parts['scheme']}:" : '' ) .
		( isset( $parts['host'] ) ? "{$parts['host']}" : '' ) .
		( isset( $parts['path'] ) ? untrailingslashit( "{$parts['path']}" ) : '' ) .
		( isset( $parts['query'] ) ? str_replace( '/', '', "?{$parts['query']}" ) : '' ) .
		( isset( $parts['fragment'] ) ? str_replace( '/', '', "#{$parts['fragment']}" ) : '' )
	);
}
