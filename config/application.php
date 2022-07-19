<?php
/**
 * Your base production configuration goes in this file.
 *
 * A good default policy is to deviate from the production config as little as
 * possible. Try to define as much of your configuration in this file as you
 * can.
 */

use Roots\WPConfig\Config;
use function Env\env;

/**
 * Directory containing all of the site's files
 *
 * @var string
 */
$root_dir = dirname(__DIR__);

/**
 * Document Root
 *
 * @var string
 */
$webroot_dir = $root_dir . '/web';

/** A couple extra tweaks to help things run well on Pantheon. **/
if (isset($_SERVER['HTTP_HOST']) ) {
    // HTTP is still the default scheme for now.
    $scheme = 'http';
    // If we have detected that the end use is HTTPS, make sure we pass that
    // through here, so <img> tags and the like don't generate mixed-mode
    // content warnings.
    if (isset($_SERVER['HTTP_USER_AGENT_HTTPS']) && $_SERVER['HTTP_USER_AGENT_HTTPS'] == 'ON') {
        $scheme = 'https';
    }

    /**
     * URLs
     */
    Config::define('WP_HOME', $scheme . '://' . $_SERVER['HTTP_HOST']);
    Config::define('WP_SITEURL', $scheme . '://' . $_SERVER['HTTP_HOST'] . '/wp');
}

/**
 * Use Dotenv to set required environment variables and load .env.pantheon file in root
 * .env.local will override .env.pantheon if it exists
 */
$env_files = file_exists($root_dir . '/.env.local')
    ? ['.env.pantheon', '.env.local']
    : ['.env.pantheon'];

$dotenv = Dotenv\Dotenv::createUnsafeImmutable($root_dir, $env_files, false);
if (file_exists($root_dir . '/.env.pantheon')) {
    $dotenv->load();
    if (!env('DATABASE_URL')) {
        $dotenv->required(['DB_NAME', 'DB_USER', 'DB_PASSWORD']);
    }
}

/**
 * Custom Content Directory
 */
Config::define('CONTENT_DIR', '/app');
Config::define('WP_CONTENT_DIR', $webroot_dir . Config::get('CONTENT_DIR'));
Config::define('WP_CONTENT_URL', Config::get('WP_HOME') . Config::get('CONTENT_DIR'));

/**
 * DB settings
 */
Config::define('DB_NAME', env('DB_NAME'));
Config::define('DB_USER', env('DB_USER'));
Config::define('DB_PASSWORD', env('DB_PASSWORD'));
Config::define('DB_HOST', $_ENV['DB_HOST'] . ':' . $_ENV['DB_PORT']);
Config::define('DB_CHARSET', 'utf8');
Config::define('DB_COLLATE', '');
$table_prefix = env('DB_PREFIX') ?: 'wp_';

if (env('DATABASE_URL')) {
    $dsn = (object) parse_url(env('DATABASE_URL'));

    Config::define('DB_NAME', substr($dsn->path, 1));
    Config::define('DB_USER', $dsn->user);
    Config::define('DB_PASSWORD', isset($dsn->pass) ? $dsn->pass : null);
}

/**
 * Authentication Unique Keys and Salts
 */
Config::define('AUTH_KEY', env('AUTH_KEY'));
Config::define('SECURE_AUTH_KEY', env('SECURE_AUTH_KEY'));
Config::define('LOGGED_IN_KEY', env('LOGGED_IN_KEY'));
Config::define('NONCE_KEY', env('NONCE_KEY'));
Config::define('AUTH_SALT', env('AUTH_SALT'));
Config::define('SECURE_AUTH_SALT', env('SECURE_AUTH_SALT'));
Config::define('LOGGED_IN_SALT', env('LOGGED_IN_SALT'));
Config::define('NONCE_SALT', env('NONCE_SALT'));

/**
 * Custom Settings
 */
// Limit the number of post revisions that Wordpress stores (true (default WP): store every revision)
Config::define('WP_POST_REVISIONS', env('WP_POST_REVISIONS') ?: true);

/**
 * Allow WordPress to detect HTTPS when used behind a reverse proxy or a load balancer
 * See https://codex.wordpress.org/Function_Reference/is_ssl#Notes
 */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// FS writes aren't permitted in test or live, so we should let WordPress know to
// disable relevant UI.
if (in_array($_ENV['PANTHEON_ENVIRONMENT'], array('test', 'live'))) {
    if (!env('DISALLOW_FILE_MODS')) {
        Config::define('DISALLOW_FILE_MODS', true);
    }
    if (!env('DISALLOW_FILE_EDIT')) {
        Config::define('DISALLOW_FILE_EDIT', true);
    }	
}

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
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * You may want to examine $_ENV['PANTHEON_ENVIRONMENT'] to set this to be
 * "true" in dev, but false in test and live.
 */
if (!env('WP_DEBUG')) {
    Config::define('WP_DEBUG', false);
}

/**
 * Force SSL
 */
if (!env('FORCE_SSL_ADMIN')) {
    Config::define( 'FORCE_SSL_ADMIN', true );
}

/** Disable wp-cron.php from running on every page load and rely on Pantheon to run cron via wp-cli */
$network = isset($_ENV["FRAMEWORK"]) && $_ENV["FRAMEWORK"] === "wordpress_network";
if (!env('DISABLE_WP_CRON') && $network === false) {
    Config::define('DISABLE_WP_CRON', true);
}

Config::apply();

/**
 * Bootstrap WordPress
 */
if (!defined('ABSPATH')) {
    define('ABSPATH', $webroot_dir . '/wp/');
}
