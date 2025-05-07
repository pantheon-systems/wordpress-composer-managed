#!/usr/bin/env bats

# wp wrapper function
_wp() {
  terminus wp -- ${SITE_ID}.dev "$@"
}

# Helper function to get REST URL via WP-CLI
get_rest_url() {
  _wp eval 'echo get_rest_url();'
}

# Helper function to get home_url path via WP-CLI
get_home_url_path() {
  _wp eval 'echo rtrim(parse_url(home_url(), PHP_URL_PATH) ?: "", "/");'
}

set_permalinks_to_pretty() {
  _wp option update permalink_structure '/%postname%/' --quiet
}

unset_pretty_permalinks() {
  _wp option update permalink_structure '' --quiet
}

flush_rewrites() {
  _wp rewrite flush --hard --quiet
}

setup_suite() {
  # Ensure WP is installed and we are in the right directory
  _wp core is-installed || (echo "WordPress not installed. Run setup script first." && exit 1)
}

teardown_test() {
  flush_rewrites # Call your helper
}

@test "Check REST URL with default (pretty) permalinks (after setup script flush)" {
  run get_rest_url
  assert_success
  # Default setup script sets /%postname%/ and flushes.
  # Expecting /wp/wp-json/ because home_url path should be /wp
  assert_output --partial "/wp/wp-json/"
}

@test "Check REST URL with plain permalinks" {
  # Set plain permalinks and flush
  _wp option update permalink_structure '' --quiet
  _wp rewrite flush --hard --quiet
  run get_rest_url
  assert_success
  # With plain permalinks, expect ?rest_route= based on home_url
  # Check if it contains the problematic /wp-json/wp/ segment (it shouldn't)
  refute_output --partial "/wp-json/wp/"
  # Check if it contains the expected ?rest_route=
  assert_output --partial "?rest_route=/"

  # Restore pretty permalinks for subsequent tests
  _wp option update permalink_structure '/%postname%/' --quiet
  _wp rewrite flush --hard --quiet
}

@test "Check REST URL with pretty permalinks *before* flush (Simulates new site)" {
  # Set pretty permalinks *without* flushing
  _wp option update permalink_structure '/%postname%/' --quiet
  # DO NOT FLUSH HERE

  # Check home_url path to confirm /wp setup
  run get_home_url_path
  assert_success
  assert_output "/wp"

  # Now check get_rest_url() - this is where the original issue might occur
  run get_rest_url
  assert_success
  # Assert that the output *should* be the correct /wp/wp-json/ even before flush,
  # assuming the fix (either integrated or separate filter) is in place.
  # If the fix is NOT in place, this might output /wp-json/ and fail.
  # If the plain permalink fix was active, it might output /wp/wp-json/wp/ and fail.
  assert_output --partial "/wp/wp-json/"
  refute_output --partial "/wp-json/wp/" # Ensure the bad structure isn't present

  # Clean up: Flush permalinks
  _wp rewrite flush --hard --quiet
}

@test "Access pretty REST API path directly with plain permalinks active" {
  # Set plain permalinks and flush
  _wp option update permalink_structure '' --quiet
  _wp rewrite flush --hard --quiet

  # Get the full home URL to construct the test URL
  SITE_URL=$( _wp option get home )
  # Construct the pretty-style REST API URL
  # Note: home_url() includes /wp, so we append /wp-json/... directly
  TEST_URL="${SITE_URL}/wp-json/wp/v2/posts"

  # Make a curl request to the pretty URL
  # -s: silent, -o /dev/null: discard body, -w '%{http_code}': output only HTTP code
  # -L: follow redirects (we expect NO redirect, so this helps verify)
  # We expect a 200 OK if the internal handling works, or maybe 404 if not found,
  # but crucially NOT a 301/302 redirect.
  run curl -s -o /dev/null -w '%{http_code}' -L "${TEST_URL}"
  assert_success
  # Assert that the final HTTP status code is 200 (OK)
  # If it were redirecting, -L would follow, but the *initial* code wouldn't be 200.
  # If the internal handling fails, it might be 404 or other error.
  assert_output "200"

  # Restore pretty permalinks for subsequent tests
  _wp option update permalink_structure '/%postname%/' --quiet
  _wp rewrite flush --hard --quiet
}
