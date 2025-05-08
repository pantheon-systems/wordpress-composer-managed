#!/usr/bin/env bats

export BATS_LIB_PATH="${BATS_LIB_PATH:-/usr/lib}"
bats_load_library bats-support
bats_load_library bats-assert

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

# Helper function to check if it's a multisite installation
_is_multisite() {
  # This command exits with 0 if it's a network (multisite) installation,
  # and 1 otherwise. We suppress output as we only care about the exit code.
  if _wp core is-installed --network > /dev/null 2>&1; then
    return 0 # true, it is multisite
  else
    return 1 # false, it is not multisite
  fi
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
  if ! _wp core is-installed; then
    echo "WordPress not installed. Run setup script first."
    exit 1
  fi
}

teardown_test() {
  flush_rewrites # Call your helper
}

@test "Check REST URL with default (pretty) permalinks" {
  set_permalinks_to_pretty
  flush_rewrites

  local rest_api_base_path
  if _is_multisite; then
    rest_api_base_path="/wp/wp-json/"
  else
    rest_api_base_path="/wp-json/"
  fi
  SITE_URL="https://dev-${SITE_ID}.pantheonsite.io${rest_api_base_path}"

  run curl -s -o /dev/null -w '%{http_code}:%{content_type}' -L "${SITE_URL}"
  assert_success "curl command failed to access ${SITE_URL}"
  # Assert that the final HTTP status code is 200 (OK) and application/json
  assert_output --partial "200:" "Expected HTTP 200 for ${SITE_URL}. Output: $output"
  assert_output --partial ":application/json" "Expected Content-Type application/json for ${SITE_URL}. Output: $output"
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
  if _is_multisite; then
    run get_home_url_path
    assert_success
    assert_output --partial "/wp"
  fi

  local rest_api_base_path
  if _is_multisite; then
    rest_api_base_path="/wp/wp-json/"
  else
    rest_api_base_path="/wp-json/"
  fi
  SITE_URL="https://dev-${SITE_ID}.pantheonsite.io${rest_api_base_path}"

  run curl -s -o /dev/null -w '%{http_code}:%{content_type}' -L "${SITE_URL}"
  assert_success "curl command failed to access ${SITE_URL} (before flush)"
  # Assert that the final HTTP status code is 200 (OK) and application/json
  # This assumes the fix ensures the correct URL works even before flushing.
  assert_output --partial "200:" "Expected HTTP 200 for ${SITE_URL} (before flush). Output: $output"
  assert_output --partial ":application/json" "Expected Content-Type application/json for ${SITE_URL} (before flush). Output: $output"
}

@test "Access pretty REST API path directly with plain permalinks active" {
  # Set plain permalinks and flush
  unset_pretty_permalinks
  flush_rewrites

  # Construct the pretty-style REST API URL for a specific endpoint
  local base_domain="https://dev-${SITE_ID}.pantheonsite.io"
  local rest_endpoint_full_path
  if _is_multisite; then
    # For multisite in /wp/, the REST API base is /wp/wp-json/
    rest_endpoint_full_path="/wp/wp-json/wp/v2/posts"
  else
    # For single site, the REST API base is /wp-json/
    rest_endpoint_full_path="/wp-json/wp/v2/posts"
  fi
  TEST_URL="${base_domain}${rest_endpoint_full_path}"

  # Make a curl request to the pretty URL
  run curl -s -o /dev/null -w '%{http_code}:%{content_type}' -L "${TEST_URL}"
  assert_success "curl command failed for ${TEST_URL}. Output: $output"
  # Assert that the final HTTP status code is 200 (OK) and application/json
  assert_output --partial "200:" "Expected HTTP 200 for ${TEST_URL}. Output: $output"
  assert_output --partial ":application/json" "Expected Content-Type application/json for ${TEST_URL}. Output: $output"

  # Restore pretty permalinks for subsequent tests
  set_permalinks_to_pretty
}

@test "Validate REST API JSON output for 'hello-world' post (with plain permalinks)" {
  unset_pretty_permalinks

  # Hardcode known post ID
  local POST_ID=1
  local base_domain="https://dev-${SITE_ID}.pantheonsite.io"
  local rest_api_base_path
  if _is_multisite; then
    rest_api_base_path="/wp/wp-json/"
  else
    rest_api_base_path="/wp-json/"
  fi
  local BASE_URL="${base_domain}${rest_api_base_path}"
  local HELLO_WORLD_API_URL="${BASE_URL}wp/v2/posts/${POST_ID}"

  # Create temp file for body
  local BODY_FILE
  BODY_FILE=$(mktemp)

  # curl writes body to BODY_FILE, metadata to stdout (captured by 'run')
  run curl -s -L -o "$BODY_FILE" \
    -w "HTTP_STATUS:%{http_code}\nCONTENT_TYPE:%{content_type}" \
    "${HELLO_WORLD_API_URL}"

  assert_success "curl command failed for ${HELLO_WORLD_API_URL}. Output: $output"

  # Parse and assert metadata from $output
  HTTP_STATUS=$(echo "$output" | grep "HTTP_STATUS:" | cut -d: -f2)
  CONTENT_TYPE=$(echo "$output" | grep "CONTENT_TYPE:" | cut -d: -f2-)

  assert_equal "$HTTP_STATUS" "200" "HTTP status was '$HTTP_STATUS', expected '200'. Full metadata: $output"

  echo "$CONTENT_TYPE" | grep -q "application/json"
  assert_success "Content-Type was '$CONTENT_TYPE', expected to contain 'application/json'. Full metadata: $output"

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
