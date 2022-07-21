<?php

use Roots\WPConfig\Config;

Config::remove('WP_HOME');
Config::remove('WP_SITEURL');
Config::remove('DB_HOST');
Config::remove('DISABLE_WP_CRON');
Config::define('DB_HOST', $_ENV['DB_HOST'] . ':' . $_ENV['DB_PORT']);

Config::apply();