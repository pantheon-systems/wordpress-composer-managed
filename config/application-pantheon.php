<?php

use Roots\WPConfig\Config;
use function Env\env;

/**
 * Use Dotenv to set required environment variables and load .env.pantheon file in root
 * .env.local will override .env.pantheon if it exists
 */
$env_files = file_exists($root_dir . '/.env.local')
    ? ['.env', '.env.pantheon', '.env.local']
    : ['.env.pantheon'];

$dotenv = Dotenv\Dotenv::createUnsafeImmutable($root_dir, $env_files, false);
if (file_exists($root_dir . '/.env.pantheon')) {
    $dotenv->load();
    if (!env('DATABASE_URL')) {
        $dotenv->required(['DB_NAME', 'DB_USER', 'DB_PASSWORD']);
    }
}

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

$network = isset($_ENV["FRAMEWORK"]) && $_ENV["FRAMEWORK"] === "wordpress_network";
/** Disable wp-cron.php from running on every page load and rely on Pantheon to run cron via wp-cli */
if (!env('DISABLE_WP_CRON') && $network === false) {
    // Config::define('DISABLE_WP_CRON', true);
}