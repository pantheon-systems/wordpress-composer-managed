#!/bin/bash
set -e

# This script handles setting up the environments necessary for running Playwright tests on different WordPress (Composer Managed) environments.

# Get variables from environment.
site_id=${SITE_ID:-""}
site_name=${SITE_NAME:-""}
site_url=${SITE_URL:-""}
type=${TYPE:-""}
terminus_token=${TERMINUS_TOKEN:-""}
commit_msg=${COMMIT_MSG:-""}
workspace=${WORKSPACE:-""}

# Set some colors.
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Set upstream ID.
UPSTREAM_NAME="WordPress (Composer Managed)"
if [ "${type}" != 'single' ]; then
  UPSTREAM_NAME="WordPress (Composer Managed) Multisite"
fi

log_into_terminus() {
  echo -e "${YELLOW}Log into Terminus${RESET}"
  terminus auth:login --machine-token="${terminus_token}"
  terminus art wordpress
}

create_site() {
  echo ""
  echo -e "${YELLOW}Create ${site_id} if it does not exist.${RESET}"
  if terminus site:info "${site_id}"; then
    echo "Test site already exists, skipping site creation."
    # If the site exists already, we should switch it to git mode.
    terminus connection:set "${site_id}".dev git -y
  else
    terminus site:create "${site_id}" "${site_name}" "${UPSTREAM_NAME}" --org=5ae1fa30-8cc4-4894-8ca9-d50628dcba17
  fi
}

clone_site() {
  echo ""
  echo -e "${YELLOW}Clone the site locally and copy PR updates${RESET}"
  echo "Setting up some git config..."
  git config --global user.email "cms-platform+sage-testing@pantheon.io"
  git config --global user.name "Pantheon WPCM Bot"
  terminus local:clone "${site_id}"
}

copy_multisite_config() {
  if [ "${type}" != 'single' ]; then
    echo ""
    echo -e "${YELLOW}Copying multisite application.php${RESET}"
    rm "${workspace}"/config/application.php
    cp "${workspace}/.github/fixtures/config/application.${type}.php" "${HOME}/pantheon-local-copies/${site_id}/config/"
    mv "${HOME}/pantheon-local-copies/${site_id}/config/application.${type}.php" "${HOME}/pantheon-local-copies/${site_id}/config/application.php"
    cd ~/pantheon-local-copies/"${site_id}"
    git add "${HOME}/pantheon-local-copies/${site_id}/config/application.php"
    git commit -m "Set up ${type} multisite config" || true
  fi
}

copy_pr_updates() {
  echo "Commit Message: ${commit_msg}"
  cd ~/pantheon-local-copies/"${site_id}"
  echo -e "${YELLOW}Copying latest changes and committing to the site.${RESET}"
  rsync -a --exclude='.git' "${workspace}"/ .
  git add -A
  git commit -m "Update to latest commit: ${commit_msg}" || true
  git push origin master || true
  terminus workflow:wait "${site_id}".dev
}

status_check() {
  echo ""
  echo -e "${YELLOW}Checking WordPress install status${RESET}"
  terminus wp "${site_id}".dev -- cli info
  if [ "${type}" != 'single' ]; then
    if ! terminus wp "${site_id}".dev -- config get MULTISITE; then
      echo -e "${RED}Multisite not found!"
      exit 1
    fi

    if [ "${type}" == 'subdir' ]; then
      # SUBDOMAIN_INSTALL should be false.
      if test terminus wp "${site_id}".dev -- config get SUBDOMAIN_INSTALL; then
        echo -e "${RED}Subdirectory configuration not found!"
        exit 1
      fi
    fi
    if [ "${type}" == 'subdom' ]; then
      # SUBDOMAIN_INSTALL should be true.
      if ! test terminus wp "${site_id}".dev -- config get SUBDOMAIN_INSTALL; then
        echo -e "${RED}Subdomain configuration not found!"
        exit 1
      fi
    fi
  fi
}

install_wp() {
  terminus wp "${site_id}".dev -- db reset
  echo ""
  # Single site.
  if [ "${type}" == 'single' ]; then
    echo -e "${YELLOW}Install (Single Site) WordPress${RESET}"
    terminus wp "${site_id}".dev -- core install --title="${site_name}" --admin_user=wpcm --admin_email=test@dev.null
  fi

  # Subdirectory multisite.
  if [ "${type}" == 'subdir' ]; then
    echo -e "${YELLOW}Install (Subdirectory Multisite) WordPress${RESET}"
    terminus wp "${site_id}".dev -- core multisite-install --title="${site_name}" --admin_user=wpcm --admin_email=test@dev.null --subdomains=false
  fi

  # Subdomain multisite.
  if [ "${type}" == 'subdom' ]; then
    echo -e "${YELLOW}Install (Subdomain Multisite) WordPress${RESET}"
    terminus wp "${site_id}".dev -- core multisite-install --title="${site_name}" --admin_user=wpcm --admin_email=test@dev.null --subdomains=true
  fi

  terminus wp "${site_id}".dev -- option update permalink_structure '/%postname%/'
  terminus wp "${site_id}".dev -- rewrite flush
  terminus wp "${site_id}".dev -- cache flush
}

set_up_subsite() {
  if [ "${type}" != 'single' ]; then
    echo ""
    echo -e "${YELLOW}Set up subsite${RESET}"
    # Set a URL var for the type of multisite.
    if [ "${type}" == 'subdom' ]; then
      URL="foo.dev-${site_id}.pantheonsite.io"
    fi
    if [ "${type}" == 'subdir' ]; then
      URL="${site_url}/foo"
    fi

    # Check if the sub-site already exists.
    EXISTING_SITE=$(terminus wp "${site_id}".dev -- site list --field=url | grep -w "foo")

    if [ -z "$EXISTING_SITE" ]; then
      # Create the sub-site only if it does not already exist.
      terminus wp "${site_id}".dev -- site create --slug=foo --title="Foo" --email="foo@dev.null"
      terminus wp "${site_id}".dev -- option update permalink_structure '/%postname%/' --url="$URL"
    else
      echo -e "${YELLOW}Sub-site already exists at $URL. Skipping creation.${RESET}"
    fi
    terminus wp "${site_id}".dev -- option update permalink_structure '/%postname%/' --url="$URL"
  fi
}

install_wp_graphql() {
  terminus connection:set "${site_id}".dev sftp
  echo ""
  echo -e "${YELLOW}Install WP GraphQL${RESET}"
  terminus wp "${site_id}".dev -- plugin install --activate wp-graphql
  terminus env:commit "${site_id}".dev --message="Install WP GraphQL"
  if [ "${type}" == 'subdom' ]; then
    # We're going to assume the foo.dev subdomain already exists.
    terminus wp "${site_id}".dev -- plugin activate wp-graphql --url=foo.dev-"${site_id}".pantheonsite.io
  fi
  if [ "${type}" == 'subdir' ]; then
    terminus wp "${site_id}".dev -- plugin activate wp-graphql --url="${site_url}"/foo
  fi
}

# Run the the steps
cd "${workspace}"
log_into_terminus
create_site
clone_site
copy_multisite_config
copy_pr_updates
status_check
install_wp
set_up_subsite
install_wp_graphql
echo "${GREEN}Done${RESET} ✨"
