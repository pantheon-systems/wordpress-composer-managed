<?php

use function Env\env;

/**
 * Directory containing all of the site's files
 *
 * @var string
 */
$root_dir = dirname(__DIR__);

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