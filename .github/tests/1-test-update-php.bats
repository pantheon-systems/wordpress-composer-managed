#!/usr/bin/env bats

custom_setup() {
  local version=$1
  # Print debugging information
  echo "BATS_TEST_DIRNAME: $BATS_TEST_DIRNAME"
  echo "Current directory before cd: $(pwd)"

  # Check if the .github directory exists
  if [ ! -d ".github" ]; then
    echo "Error: .github directory not found in $(pwd)"
    exit 1
  fi

  if [ ! -f "pantheon.upstream.yml" ]; then
    echo "It doesn't look like you are in an upstream repository. Check the current directory: $(pwd)"
    exit 1
  fi

  # Copy the fixture file to pantheon.yml before each test
  cp ".github/fixtures/pantheon-${version}.yml" pantheon.yml
}

teardown() {
  # Clean up by removing the pantheon.yml file after each test
  rm -f pantheon.yml
}

@test "Update PHP version 7.4 to 8.1" {
  custom_setup "74"
  run bash private/scripts/helpers.sh update_php
  echo "$output"
  [ "$status" -eq 0 ]
  run grep -q "php_version: 8.1" pantheon.yml
  [ "$status" -eq 0 ]
}

@test "Update PHP version 8.0 to 8.1" {
  custom_setup "80"
  run bash private/scripts/helpers.sh update_php
  echo "$output"
  [ "$status" -eq 0 ]
  run grep -q "php_version: 8.1" pantheon.yml
  [ "$status" -eq 0 ]
}

@test "Keep PHP version 8.1" {
  custom_setup "81"
  run bash private/scripts/helpers.sh update_php
  echo "$output"
  [ "$status" -eq 0 ]
  run grep -q "php_version: 8.1" pantheon.yml
  [ "$status" -eq 0 ]
}

@test "Keep PHP version 8.2" {
  custom_setup "82"
  run bash private/scripts/helpers.sh update_php
  echo "$output"
  [ "$status" -eq 0 ]
  run grep -q "php_version: 8.2" pantheon.yml
  [ "$status" -eq 0 ]
}

@test "Keep PHP version 8.3" {
  custom_setup "83"
  run bash private/scripts/helpers.sh update_php
  echo "$output"
  [ "$status" -eq 0 ]
  run grep -q "php_version: 8.3" pantheon.yml
  [ "$status" -eq 0 ]
}
