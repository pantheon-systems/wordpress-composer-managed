<?php
/**
 * This is where you should at your configuration customizations. It will work out of the box on Pantheon
 * but you may find there are a lot of neat tricks to be used here.
 *
 * See our documentation for more details:
 *
 * https://pantheon.io/docs
 */

require_once dirname(__DIR__) . '/vendor/autoload.php';

/**
 * Pantheon platform settings. Everything you need should already be set.
 */
if (file_exists(dirname(__FILE__) . '/wp-config-pantheon.php') && isset($_ENV['PANTHEON_ENVIRONMENT'])) {
	require_once(dirname(__FILE__) . '/wp-config-pantheon.php');
}

require_once dirname(__DIR__) . '/config/application.php';

require_once ABSPATH . 'wp-settings.php';