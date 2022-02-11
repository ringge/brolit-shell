#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha5
#############################################################################

function postgres_default_installer() {

  package_is_installed "postgresql"

  exitstatus=$?
  if [ ${exitstatus} -eq 0 ]; then

    log_event "info" "Postgres is already installed" "false"

    return 1

  else

    log_subsection "Postgres Installer"

    log_event "info" "Running Postgres default installer" "false"

    apt-get --yes install postgresql postgresql-contrib -qq >/dev/null

    display --indent 6 --text "- Postgres default installation" --result "DONE" --color GREEN

    return 0

  fi

}

function postgres_purge_installation() {

  # Log
  log_event "warning" "Purging mysql-* packages ..." "false"
  display --indent 6 --text "- Purging MySQL packages"

  # Apt
  apt-get --yes purge postgresql postgresql-contrib -qq >/dev/null
  apt-get autoremove -qq >/dev/null
  apt-get autoclean -qq >/dev/null

  # Log
  clear_previous_lines "1"
  log_event "info" "postgresql postgresql-contrib packages purged!" "false"
  display --indent 6 --text "- Purging Postgres packages" --result "DONE" --color GREEN

}

function postgres_check_if_installed() {

  POSTGRES="$(which psql)"
  if [[ ! -x "${POSTGRES}" ]]; then
    postgres_installed="false"
  fi

}

function postgres_check_installed_version() {

  psql --version | awk '{ print $5 }' | awk -F\, '{ print $1 }'

}

