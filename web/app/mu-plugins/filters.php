<?php
/**
 * Plugin Name: Pantheon WordPress Filters
 * Plugin URI:   https://github.com/pantheon-systems/wordpress-composer-managed
 * Description:  Filters for Composer-managed WordPress sites on Pantheon.
 * Version:      1.2.3
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

/**
 * REST API Plain Permalink Fix
 *
 * Extracts the REST API endpoint from a potentially malformed path.
 * Handles cases like /wp-json/v2/posts or /wp-json/wp/v2/posts.
 *
 * @since 1.2.3
 * @param string $path The URL path component.
 * @return string The extracted endpoint (e.g., /v2/posts) or '/'.
 */
function __extract_rest_endpoint( string $path ) : string {
	$rest_route = '/'; // Default to base route
	$wp_json_pos = strpos( $path, '/wp-json/' );

    if ( $wp_json_pos === false ) {
        return $rest_route; // Return base if /wp-json/ not found
    }

    $extracted_route = substr( $path, $wp_json_pos + strlen( '/wp-json' ) ); // Get everything after /wp-json
    // Special case: Handle the originally reported '/wp-json/wp/' malformation
    if ( strpos( $extracted_route, 'wp/' ) === 0 ) {
        $extracted_route = substr( $extracted_route, strlen( 'wp' ) ); // Remove the extra 'wp'
    }
    // Ensure the extracted route starts with a slash
    if ( ! $extracted_route && $extracted_route[0] !== '/' ) {
        $extracted_route = '/' . $extracted_route;
    }
    $rest_route = $extracted_route ?: '/'; // Use extracted route or default to base

	return $rest_route;
}

/**
 * Builds the correct plain permalink REST URL.
 *
 * @since 1.2.3
 * @param string $endpoint The REST endpoint (e.g., /v2/posts).
 * @param string|null $query_str The original query string (or null).
 * @param string|null $fragment The original fragment (or null).
 * @return string The fully constructed plain permalink REST URL.
 */
function __build_plain_rest_url( string $endpoint, ?string $query_str, ?string $fragment ) : string {
	$home_url = home_url(); // Should be https://.../wp
	// Ensure endpoint starts with /
	$endpoint = '/' . ltrim( $endpoint, '/' );
	// Construct the base plain permalink URL
	$correct_url = rtrim( $home_url, '/' ) . '/?rest_route=' . $endpoint;

	// Append original query parameters (if any, besides rest_route)
	if ( ! empty( $query_str ) ) {
		parse_str( $query_str, $query_params );
		unset( $query_params['rest_route'] ); // Ensure no leftover rest_route
		if ( ! empty( $query_params ) ) {
			// Check if $correct_url already has '?' (it should)
			$correct_url .= '&' . http_build_query( $query_params );
		}
	}
	// Append fragment if present
	if ( ! empty( $fragment ) ) {
		$correct_url .= '#' . $fragment;
	}

	// Use normalization helper if available
	if ( function_exists( __NAMESPACE__ . '\\__normalize_wp_url' ) ) {
		return __normalize_wp_url( $correct_url );
	}

    return $correct_url; // Return without full normalization as fallback
}

/**
 * Corrects generated REST API URL when plain permalinks are active but WordPress
 * incorrectly generates a pretty-permalink-style path. Forces the URL
 * back to the expected ?rest_route= format using helpers.
 *
 * @since 1.2.3
 * @param string $url The potentially incorrect REST URL generated by WP.
 * @return string The corrected REST URL in plain permalink format.
 */
function filter_force_plain_rest_url_format( string $url ) : string {
	$parsed_url = parse_url($url);

	// Check if it looks like a pretty permalink URL (has /wp-json/ in path)
	// AND lacks the ?rest_route= query parameter.
	$has_wp_json_path = isset( $parsed_url['path'] ) && strpos( $parsed_url['path'], '/wp-json/' ) !== false;
	$has_rest_route_query = isset( $parsed_url['query'] ) && strpos( $parsed_url['query'], 'rest_route=' ) !== false;

	if ( $has_wp_json_path && ! $has_rest_route_query ) {
		// It's using a pretty path format when it shouldn't be.
		$endpoint = __extract_rest_endpoint( $parsed_url['path'] );
		return __build_plain_rest_url( $endpoint, $parsed_url['query'] ?? null, $parsed_url['fragment'] ?? null );
	}

	// If the URL didn't match the problematic pattern, return it normalized.
    return __normalize_wp_url($url);
}

/**
 * Handles incoming requests using a pretty REST API path format when plain
 * permalinks are active. It sets the correct 'rest_route' query variable
 * internally instead of performing an external redirect.
 *
 * @since 1.2.3
 * @param \WP $wp The WP object, passed by reference.
 */
function handle_pretty_rest_request_on_plain_permalinks( \WP &$wp ) {
	// Only run if it's not an admin request. Permalink structure checked by the hook caller.
	if ( is_admin() ) {
		return;
	}

	// Use REQUEST_URI as it's more reliable for the raw request path before WP parsing.
	$request_uri = $_SERVER['REQUEST_URI'] ?? '';
	// Get the path part before any query string.
	$request_path = strtok($request_uri, '?');

	// Define the pretty permalink base path we expect if pretty permalinks *were* active.
	$home_url_path = rtrim( parse_url( home_url(), PHP_URL_PATH ) ?: '', '/' ); // e.g., /wp
	$pretty_rest_path_base = $home_url_path . '/wp-json/'; // e.g., /wp/wp-json/

	// Check if the actual request path starts with this pretty base.
	if ( strpos( $request_path, $pretty_rest_path_base ) === 0 ) {
		// Extract the endpoint part *after* the base.
		$endpoint = substr( $request_path, strlen( $pretty_rest_path_base ) );
		// Ensure endpoint starts with a slash, default to base if empty.
		$endpoint = '/' . ltrim($endpoint, '/');
		// If the result is just '/', set it back to empty string for root endpoint ?rest_route=/
		$endpoint = ($endpoint === '/') ? '' : $endpoint;

		// Check if rest_route is already set (e.g., from query string), if so, don't overwrite.
		// This prevents conflicts if someone manually crafts a URL like /wp/wp-json/posts?rest_route=/users
		if ( ! isset( $wp->query_vars['rest_route'] ) ) {
			// Directly set the query variable for the REST API.
			$wp->query_vars['rest_route'] = $endpoint;

		}
		// No redirect, no exit. Let WP continue processing with the modified query vars.
	}
}

// Only add the REST URL *generation* fix and the request handler if plain permalinks are enabled.
if ( ! get_option('permalink_structure') ) {
	add_filter('rest_url', __NAMESPACE__ . '\\filter_force_plain_rest_url_format', 10, 1);
	// Hook the request handling logic to parse_request. Pass the $wp object by reference.
	add_action('parse_request', __NAMESPACE__ . '\\handle_pretty_rest_request_on_plain_permalinks', 1, 1);
}
