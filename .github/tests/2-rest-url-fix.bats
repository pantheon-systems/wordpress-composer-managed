#!/usr/bin/env bats

export BATS_LIB_PATH="${BATS_LIB_PATH:-/usr/lib}"
bats_load_library bats-support
bats_load_library bats-assert

# wp wrapper function
_wp() {
  # Capture all output, then filter.
  # The `|| true` prevents the command from exiting the script if terminus
  # returns a non-zero exit code but still outputs something we might want to
  # see for debugging (though BATS will catch the failure).
  local raw_output
  raw_output=$(terminus wp -- ${SITE_ID}.dev "$@" 2>&1 || true)

  # Filter out known Terminus noise and extract the relevant line.
  # This tries to get the last line that is NOT a warning or a command notice.
  echo "$raw_output" | \
    grep -vE "(^\[warning\]|^\[notice\] Command:)" | \
    grep -vE "^Deprecated: rtrim\(\): Passing null to parameter #1" | \
    tail -n 1
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
  unset_pretty_permalinks
  flush_rewrites

  run get_rest_url
  assert_success
  # With plain permalinks, expect ?rest_route= based on home_url
  # Check if it contains the problematic /wp-json/wp/ segment (it shouldn't)
  refute_output --partial "/wp-json/wp/"
  # Check if it contains the expected ?rest_route=
  assert_output --partial "?rest_route=/"

  # Restore pretty permalinks for subsequent tests
  set_permalinks_to_pretty
}

@test "Check REST URL with pretty permalinks *before* flush (Simulates new site)" {
  # Set pretty permalinks *without* flushing
  set_permalinks_to_pretty
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
}

@test "Access pretty REST API path directly with plain permalinks active" {
  # Set plain permalinks and flush
  unset_pretty_permalinks
  flush_rewrites

  # Get the full home URL to construct the test URL
  SITE_URL=$( _wp option get home )
  # Construct the pretty-style REST API URL
  # Note: home_url() includes /wp, so we append /wp-json/... directly
  TEST_URL="${SITE_URL}/wp-json/wp/v2/posts"

  # Make a curl request to the pretty URL
  run curl -s -o /dev/null -w '%{http_code}:%{content_type}' -L "${TEST_URL}"
  assert_success
  # Assert that the final HTTP status code is 200 (OK) and application/json
  assert_output --partial "200:application/json"

  # Restore pretty permalinks for subsequent tests
  set_permalinks_to_pretty
}

@test "Validate REST API JSON output for 'hello-world' post (with plain permalinks)" {
  unset_pretty_permalinks

  SITE_URL=$( _wp option get home )
  # Get the ID of the 'hello-world' post.
  POST_ID=$( _wp post list --post_type=post --name=hello-world --field=ID --format=ids )
  assert_not_empty "$POST_ID" "The 'Hello world!' post (slug: hello-world) was not found."

  # Even with plain permalinks, we test accessing the pretty REST API path
  HELLO_WORLD_API_URL="${SITE_URL}/wp-json/wp/v2/posts/${POST_ID}"
  BODY_FILE=$(mktemp)
  trap 'rm -f "$BODY_FILE"' EXIT # Ensure cleanup

  # curl writes body to BODY_FILE, metadata to stdout (captured by 'run')
  run curl -s -L -o "$BODY_FILE" \
    -w "HTTP_STATUS:%{http_code}\nCONTENT_TYPE:%{content_type}" \
    "${HELLO_WORLD_API_URL}"

  assert_success "curl command failed for ${HELLO_WORLD_API_URL}. Output: $output"

  # Parse and assert metadata from $output
  HTTP_STATUS=$(echo "$output" | grep "HTTP_STATUS:" | cut -d: -f2)
  CONTENT_TYPE=$(echo "$output" | grep "CONTENT_TYPE:" | cut -d: -f2-)

  assert_equal "$HTTP_STATUS" "200" "HTTP status was '$HTTP_STATUS', expected '200'. Full metadata: $output"
  assert_match "$CONTENT_TYPE" "application/json" "Content-Type was '$ CONTENT_TYPE', expected to contain 'application/json'. Full metadata: $output"

  JSON_BODY=$(cat "$BODY_FILE")

  echo "$JSON_BODY" | jq -e . > /dev/null
  assert_success "Response body is not valid JSON. Body: $JSON_BODY"

  run jq -e ".id == ${POST_ID}" <<< "$JSON_BODY"
  assert_success "JSON .id mismatch. Expected ${POST_ID}. Body: $JSON_BODY"

  run jq -e '.slug == "hello-world"' <<< "$JSON_BODY"
  assert_success "JSON .slug mismatch. Expected 'hello-world'. Body: $JSON_BODY"

  run jq -e '.title.rendered == "Hello world!"' <<< "$JSON_BODY"
  assert_success "JSON .title.rendered mismatch. Expected 'Hello world!'. Body: $JSON_BODY"

  set_permalinks_to_pretty
}
