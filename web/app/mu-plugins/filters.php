<?php
/**
 * Plugin Name: Pantheon WordPress Filters
 * Plugin URI:   https://github.com/pantheon-systems/wordpress-composer-managed
 * Description:  Filters for Composer-managed WordPress sites on Pantheon.
 * Version:      1.0.0
 * Author:       Pantheon Systems
 * Author URI:   https://pantheon.io/
 * License:      MIT License
 */


/**
 * Update the multisite configuration to use Config::define() instead of define.
 *
 * @return string
 */
add_filter( 'pantheon.multisite.config_contents', function ( $config_contents ) {
	$config_contents = str_replace( 'define(', 'Config::define(', $config_contents );
	return $config_contents;
} );
