
#!/usr/bin/env bash

# Get the site name, theme name, and SFTP credentials from the user.
function get_info() {
  # If is_restarted is unset, set it to 0.
  if [ -z "$is_restarted" ]; then
    is_restarted=0
  fi

  dashboard_link="https://dashboard.pantheon.io/sites/${id}#dev/code"

  # Unset the variables if we're doing this a second time.
  if [ $is_restarted == 1 ]; then
    unset sitename
    unset sagename
    unset sftpuser
    unset sftphost
  fi

  if [ $is_restarted == 0 ]; then
    echo -e "${yellow}Finding site information...${normal}\n"
  fi

  # Set up some defaults. These should evaluate to false if you go through
  # the prompts once but say no to the confirmation because at that point we
  # set them to empty strings.
  # There's some discussion about the brackets distinction in this
  # StackOverflow: https://stackoverflow.com/a/13864829/1351526
  if [ $is_restarted == 0 ] && [ -z "$sitename" ]; then
    echo "Found site name! Using ${name}."
    sitename=$name
  fi

  if [ $is_restarted == 0 ] && [ -z "$sftpuser" ]; then
    echo "Found SFTP username! Using dev.${id}."
    sftpuser=dev.$id
  fi

  if [ $is_restarted == 0 ] && [ -z "$sftphost" ]; then
    echo "Found SFTP host name! Using appserver.dev.${id}.drush.in."
    sftphost=appserver.dev.$id.drush.in
  fi

  if [ $is_restarted == 0 ]; then
    echo -e "\n--------------------------------------------------------------------------"
  fi
  # We want these to evaluate to false if they're empty strings so they can be
  # set manually.
  if [ -z "$sitename" ]; then
    echo -e "${yellow}Enter the site name.${normal}\nThis will be used to interact with your site. The default is ${green}${name}${normal}."
    read -p "Site name: " -r sitename
  else
    echo -e "${green}Site name: ${normal}${sitename}"
  fi

  if [ -z "$sftpuser" ]; then
    echo -e "${yellow}Enter your SFTP username.${normal}\nThis will only be stored in this terminal session. This can be found in your site dashboard. The default is ${green}dev.${id}${normal}. \nDashboard link: ${dashboard_link}"
    read -p "SFTP username: " -r sftpuser
  else
    echo -e "${green}SFTP username: ${normal}${sftpuser}"
  fi

  if [ -z "$sftphost" ]; then
    echo -e "${yellow}Enter your SFTP hostname.${normal}\nThis will only be stored in this terminal session. This can be found in your site dashboard. The default is ${green}appserver.dev.${id}.drush.in${normal}. \nDashboard link: ${dashboard_link}"
    read -p "SFTP hostname: " -r sftphost
  else
    echo -e "${green}SFTP hostname: ${normal}${sftphost}"
  fi

  if [ $is_restarted == 0 ]; then
    echo -e "--------------------------------------------------------------------------\n"
  fi

  # This is the first input that doesn't have a default. We'll do the line break above this.
  if [ -z "$sagename" ]; then
    echo -e "${yellow}Enter your theme name.${normal}\nThis is used to create the theme directory. As such, it should ideally be all lowercase with no spaces (hyphens or underscores recommended)\n"
    read -p "Theme name: " -r sagename
  else
    echo -e "${green}Theme name: ${sagename}${normal}"
  fi

  echo "You've entered:
  Site name: ${sitename}
  Theme name: ${sagename}
  SFTP username: ${sftpuser}
  SFTP hostname: ${sftphost}"
  read -p "Is this correct? (y/n) " -n 1 -r
  # If the user enters n, redo the prompts.
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "\nRestarting...\n"

    # Toggle the restarted state.
    is_restarted=1

    get_info
  fi

  if [ -z "$sitename" ] || [ -z "$sagename" ] || [ -z "$sftpuser" ] || [ -z "$sftphost" ]; then
    echo -e "\n${red}Missing information!${normal} Make sure you've everything for all the prompts.\n"
    get_info
  fi

  # Set the theme directory. Do this at the end, after we know what everything should be.
  sagedir=$themedir/$sagename
}

# Use terminus whoami to check if the user is logged in and exit the script if they are not.
function check_login() {
  echo -e "${yellow}Checking if you are logged in to Terminus...${normal}"
  # Read the response from terminus whoami into the REPLY variable.
  REPLY=$(terminus whoami)

  # If the response does not include a @, you're not logged in.
  # Ask the user to log in and exit.
  if [[ $REPLY != *"@"* ]]; then
    echo -e "${red}You are not logged in to Terminus.${normal}\nPlease authenticate with terminus first using ${bold}terminus auth:login${normal}"
    exit 1;
  fi
}

# Get a field from the output of terminus site:info.
get_field() {
  local input="$1"
  # Remove leading and trailing whitespace from each line
  input="$(echo "$input" | sed -e 's/^[ \t]*//')"

  # Remove the first and last lines that are entirely dashes
  input="$(echo "$input" | sed -e '1d' -e '$d')"
  # $1: field name
  # $2: input string
  echo "$2" | awk -v field="$1" '$1 == field { print $2 }'
}

# Update to PHP 8.0
function update_php() {
  echo -e "\n\n${yellow}Updating PHP version to 8.0.${normal}"
  sed -i '' "s/php_version: 7.4/php_version: 8.0/" pantheon.upstream.yml
  git commit -am "[Sage Install] Update PHP version to 8.0"
  git push origin master
}

# Install sage and related dependencies.
function install_sage() {
  # Check if the directory $sagedir is empty. If it's not, bail.
  echo -e "Checking if ${sagedir} is exists and if it's empty.\n"

  if [ "$(ls -A $sagedir)" ]; then
    echo -e "${red}Directory not empty!${normal}\n Trying to install into ${sagedir}. Exiting."
    exit 1;
  fi

  echo -e "${yellow}Installing Sage.${normal}"
  # Create the new Sage theme
  composer create-project roots/sage $sagedir

  # Require Roots/acorn
  composer require roots/acorn --working-dir=$sagedir

  # Install all the Sage dependencies
  composer install --no-dev --prefer-dist --working-dir=$sagedir

  # NPM the things
  npm install --prefix $sagedir
  npm run build --prefix $sagedir

  # Remove /public from .gitignore
  sed -i '' "s/\/public//" $sagedir/.gitignore

  # Commit the theme
  git add $sagedir
  git commit -m "[Sage Install] Add the Sage theme ${sagename}."
  git push origin master
  echo -e "${green}Sage installed!${normal}\n"
}

# Create the symlink to the cache directory.
function add_symlink() {
  # Switch to SFTP mode
  terminus connection:set $sitename.dev sftp

  if [ ! -d "web/app/uploads" ]; then
    echo -e "${yellow}Creating the uploads directory.${normal}"
    mkdir web/app/uploads
  fi

  if [ ! -d "web/app/uploads/cache" ]; then
    echo -e "${yellow}Creating the cache directory.${normal}"
    mkdir web/app/uploads/cache
  fi

  # Create a files/cache directory on the host.
  sftp -P 2222 $sftpuser@$sftphost <<EOF
    cd /files
    mkdir cache
EOF

    # Switch back to Git mode.
    terminus connection:set $sitename.dev git

  # Create the symlink to /files/cache.
  cd web/app
  echo -e "${yellow}Adding a symlink to the cache directory.${normal}"
  ln -sfn uploads/cache
  git add .
  git commit -m "[Sage Install] Add a symlink for /files/cache to /uploads/cache"
  git push origin master
  cd ../..
}

# Add a post-install hook to the composer.json.
function update_composer() {
  composer update
  # Check if the lock file has been modified.
  if [ -n "$(git status --porcelain)" ]; then
    echo -e "${yellow}Updating composer.lock.${normal}"
    git add composer.lock
    git commit -m "[Sage Install] Update composer.lock"
    git push origin master
  fi

  echo -e "${yellow}Attempting to add a post-install hook to composer.json.${normal}"

  # Check of jq is installed
  if [ ! command -v jq &> /dev/null ]; then
    if [ ! command -v brew & /dev/null ]; then
      echo "${yellow}Brew was not found. Exiting here. You'll need to add the following lines to your `composer.json`:${normal}"
      echo '  "scripts": {'
      echo '      "post-install-cmd": ['
      echo "          \"@composer install --no-dev --prefer-dist --ignore-platform-reqs --working-dir=web/app/themes/$sagename\""
      echo '      ],'
      exit
    fi
    brew install jq
  fi

  # Add a post-install hook to the composer.json.
  echo -e "${yellow}Adding a post-install hook to composer.json.${normal}"
  jq -r '.scripts += { "post-install-cmd": [ "@composer install --no-dev --prefer-dist --ignore-platform-reqs --working-dir=%sagedir%" ] }' composer.json > composer.new.json
  sed -i '' "s,%sagedir%,$sagedir," composer.new.json
  rm composer.json
  mv composer.new.json composer.json

  # Commit the change to composer.json
  git add composer.json
  git commit -m "[Sage Install] Add post-install-cmd hook to also run install on ${sagename}"

  git pull --ff --commit
  git push origin master
  if [ $? -ne 0 ]; then
    echo -e "\n${red}Push failed. Stopping here.${normal}\nNext steps are to push the changes to the repo and then set the connection mode back to Git."
    exit 1;
  fi

  # Wait for the build to finish.
  echo -e "${yellow}Waiting for the deploy to finish.${normal}"
  terminus workflow:wait --max=30 $sitename.dev
  if [ $? -ne 0 ]; then
    echo -e "\n${red}terminus workflow:wait command not found. Stopping here.${normal}\nYou will need to install the terminus-build-tools-plugin.\nterminus self:plugin:install terminus-build-tools-plugin"
    exit 1;
  fi

  # Check for long-running workflows.
  if [[ "$(terminus workflow:wait --max=1 ${sitename}.dev)" == *"running"* ]]; then
    echo -e "${yellow}Workflow still running, waiting another 30 seconds.${normal}"
    terminus workflow:wait --max=30 $sitename.dev
  fi
}

# Finish up the Sage install process.
function clean_up() {
  # If the site is multisite, we'll need to enable the theme so we can activate it.
  terminus wp -- $sitename.dev theme enable $sagename
  # List the themes.
  terminus wp -- $sitename.dev theme list

  # Activate the new theme
  echo -e "${yellow}Activating the ${sagename} theme.${normal}"
  terminus wp -- $sitename.dev theme activate $sagename
  if [ $? -ne 0 ]; then
    echo -e "${red}Theme activation failed. Exiting here.${normal}\nCheck the theme list above. If the theme you created is not listed, it's possible that the deploy has not completed. You can try again in a few minutes using the following command:\nterminus wp -- $sitename.dev theme activate $sagename\nOnce you do this, you will need to open the site to generate the requisite files and then commit them in SFTP mode.\n5. You're ready to go! Set the connection mode back to Git."
    exit 1;
  fi

  # Switch back to SFTP so files can be written.
  terminus connection:set $sitename.dev sftp

  # Open the site. This should generate requisite files on page load.
  echo -e "${yellow}Opening the dev-${sitename}.pantheonsite.io to generate requisite files.${normal}"
  open https://dev-$sitename.pantheonsite.io

  # Commit any additions found in SFTP mode.
  echo -e "${yellow}Committing any files found in SFTP mode that were created by Sage.${normal}"
  terminus env:commit $sitename.dev --message="[Sage Install] Add any leftover files found in SFTP mode."

  # Switch back to Git.
  terminus connection:set $sitename.dev git
  git pull --ff --commit
}

# Defines some global variables for colors.
normal=$(tput sgr0)
bold=$(tput bold)
italic=$(tput sitm)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)

# Check if the user is logged into Terminus before trying to run other Terminus commands.
check_login

themedir="web/app/themes"
siteinfo=$(terminus site:info)
id=$(get_field "ID" "$siteinfo")
name=$(get_field "Name" "$siteinfo")

get_info
update_php
install_sage
add_symlink
update_composer
clean_up
