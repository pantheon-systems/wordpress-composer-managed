<?php

use Roots\WPConfig\Config;

Config::define('DB_HOST', $_ENV['DB_HOST'] . ':' . $_ENV['DB_PORT']);

Config::apply();