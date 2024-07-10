<?php
/**
 * This is where you should at your configuration customizations. It will work out of the box on Pantheon
 * but you may find there are a lot of neat tricks to be used here.'
 *
 * For local development, see .env.local-sample.
 *
 * See our documentation for more details:
 *
 * https://pantheon.io/docs
 */

require_once dirname(__DIR__) . '/vendor/autoload.php';

/**
 * Pantheon platform settings are defined in config/application.pantheon.php which is called by config/application.php. Everything you need should already be set.
 */

require_once dirname(__DIR__) . '/config/application.php';

require_once ABSPATH . 'wp-settings.php';
