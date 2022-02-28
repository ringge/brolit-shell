#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha8
################################################################################
#
# Backup/Restore Helper: Backup and restore funtions.
#
################################################################################

################################################################################
# Make temp directory backup.
# This should be executed if we want to restore a file backup on directory
# with the same name.
#
# Arguments:
#   $1 = ${folder_to_backup}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function _make_temp_files_backup() {

  local folder_to_backup=$1

  display --indent 6 --text "- Creating backup on temp directory"

  # Moving project files to temp directory
  mkdir "${BROLIT_MAIN_DIR}/tmp/old_backups"
  mv "${folder_to_backup}" "${BROLIT_MAIN_DIR}/tmp/old_backups"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Log
    clear_previous_lines "1"
    log_event "info" "Temp backup completed and stored here: ${BROLIT_MAIN_DIR}/tmp/old_backups" "false"
    display --indent 6 --text "- Creating backup on temp directory" --result "DONE" --color GREEN

    return 0

  else

    # Log
    display --indent 6 --text "-- ERROR: Could not move project files to temp directory"

    return 1

  fi

}

#
#################################################################################
#
# * Public Funtions
#
#################################################################################
#

################################################################################
# Restore backup from local file
#
# Arguments:
#   $1 = ${folder_to_backup}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_backup_from_local_file() {

  local -n restore_type # whiptail array options
  local chosen_restore_type

  # TODO: Restore project?

  restore_type=(
    "01)" "RESTORE FILES"
    "02)" "RESTORE DATABASE"
  )
  chosen_restore_type="$(whiptail --title "RESTORE FROM LOCAL" --menu " " 20 78 10 "${restore_type[@]}" 3>&1 1>&2 2>&3)"
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    if [[ ${chosen_restore_type} == *"01"* ]]; then

      # RESTORE FILES
      log_subsection "Restore files from local"

      # Folder where sites are hosted: $PROJECTS_PATH
      menu_title="SELECT BACKUP FILE TO RESTORE"
      file_browser "${menu_title}" "${PROJECTS_PATH}"

      # Directory_broser returns: " $filepath"/"$filename
      if [[ -z "${filepath}" || "${filepath}" == "" ]]; then

        log_event "info" "Operation cancelled!" "false"

        # Return
        #return 1

      else

        log_event "info" "File to restore: ${filename}" "false"

        # Ask project domain
        project_domain="$(ask_project_domain "")"

        # Decompress backup
        mkdir -p "${BROLIT_TMP_DIR}/${project_domain}"
        decompress "${filename}" "${BROLIT_TMP_DIR}/${project_domain}" "lbzip2"

        dir_count="$(count_directories_on_directory "${BROLIT_TMP_DIR}/${project_domain}")"

        if [[ ${dir_count} -eq 1 ]]; then

          # Move files one level up
          main_dir="$(ls -1 "${BROLIT_TMP_DIR}/${project_domain}")"
          mv "${BROLIT_TMP_DIR}/${project_domain}/${main_dir}/"{.,}* "${BROLIT_TMP_DIR}/${project_domain}"

        fi

        exitstatus=$?
        if [[ ${exitstatus} -eq 1 ]]; then
          return 1
        fi

        # TODO: search for .sql or sql.gz files

        # We don't have a domain yet so let "restore_backup_files" ask
        restore_backup_files ""

        # TODO: restore_type_selection_from_dropbox needs a refactor too

      fi

    fi

    if [[ ${chosen_restore_type} == *"02"* ]]; then

      #RESTORE DATABASE
      log_subsection "Restore database from file"

      # Folder where sites are hosted: $PROJECTS_PATH
      menu_title="SELECT BACKUP FILE TO RESTORE"
      file_browser "${menu_title}" "${PROJECTS_PATH}"

      # Directory_broser returns: " $filepath"/"$filename
      if [[ -z "${filepath}" || "${filepath}" == "" ]]; then

        log_event "info" "Operation cancelled!" "false"

        # Return
        #return 1

      else

        log_event "info" "File to restore: ${filepath}/${filename}" "false"

        # Copy to tmp dir
        cp "${filepath}/${filename}" "${BROLIT_TMP_DIR}"

        project_name="$(ask_project_name "")"
        project_state="$(ask_project_state "")"

        restore_database_backup "${project_name}" "${project_state}" "${filename}"

      fi

    fi

  fi

}

################################################################################
# Restore backup from ftp/sftp server
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_backup_from_ftp() {

  whiptail_message_with_skip_option "RESTORE FROM FTP" "The script will prompt you for project details and the FTP credentials. Then it will download all files one by one. If a .sql or .sql.gz is present, it will ask you if you want to restore the database too."

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # RESTORE FILES
    log_subsection "Restore files from ftp"

    # Ask project state
    project_state="$(ask_project_state "prod")"

    # Ask project domain
    project_domain="$(ask_project_domain "")"

    possible_project_domain="$(project_get_name_from_domain "${project_domain}")"

    # Ask project name
    project_name="$(ask_project_name "${possible_project_domain}")"

    # FTP
    ftp_domain="$(whiptail_imput "FTP SERVER IP/DOMAIN" "Please insert de FTP server IP/DOMAIN. Ex: ftp.domain.com")"
    ftp_path="$(whiptail_imput "FTP SERVER PATH" "Please insert de FTP server path. Ex: /htdocs/website")"
    ftp_user="$(whiptail_imput "FTP SERVER USER" "Please insert de FTP user.")"
    ftp_pass="$(whiptail_imput "FTP SERVER PASS" "Please insert de FTP password.")"

    ## Download files from ftp
    ftp_download "${ftp_domain}" "${ftp_path}" "${ftp_user}" "${ftp_pass}" "${BROLIT_TMP_DIR}/${project_domain}"

    exitstatus=$?
    if [[ ${exitstatus} -eq 1 ]]; then

      # Log
      log_event "error" "FTP connection failed!" "false"
      display --indent 6 --text "- Restore project" --result "FAIL" --color RED

      return 1

    fi

    # Search for .sql or sql.gz files
    local find_result

    # Find backups from downloaded ftp files
    find_result="$({
      find "${BROLIT_TMP_DIR}/${project_domain}" -name "*.sql"
      find "${BROLIT_TMP_DIR}/${project_domain}" -name "*.sql.gz"
    })"

    if [[ ${find_result} != "" ]]; then

      log_event "info" "Database backups found on downloaded files" "false"

      array_to_checklist "${find_result}"

      # Backup file selection
      chosen_database_backup="$(whiptail --title "DATABASE TO RESTORE" --checklist "Select the database backup you want to restore." 20 78 15 "${checklist_array[@]}" 3>&1 1>&2 2>&3)"

      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then

        # Restore database
        restore_database_backup "${project_name}" "${project_state}" "${chosen_database_backup}"

      else

        log_event "info" "Database backup selection skipped" "false"
        display --indent 6 --text "- Database backup selection" --result "SKIPPED" --color YELLOW

      fi

    fi

    # Restore files
    move_files "${BROLIT_TMP_DIR}/${project_domain}" "${PROJECTS_PATH}"

  fi

}

################################################################################
# Restore backup from public url (ex: https://domain.com/backup.tar.gz)
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_backup_from_public_url() {

  local project_state
  local project_domain
  local project_name
  local possible_project_name
  local root_domain
  local possible_root_domain

  # RESTORE FILES
  log_subsection "Restore files from public URL"

  # Ask project state
  project_state="$(ask_project_state "prod")"

  # Project domain
  project_domain="$(ask_project_domain "")"

  # Cloudflare support
  if [[ ${SUPPORT_CLOUDFLARE_STATUS} == "enabled" ]]; then
    possible_root_domain="$(get_root_domain "${project_domain}")"
    root_domain="$(cloudflare_ask_rootdomain "${possible_root_domain}")"
  fi

  # Project name
  possible_project_name="$(project_get_name_from_domain "${project_domain}")"
  project_name="$(ask_project_name "${possible_project_name}")"

  source_files_url=$(whiptail --title "Source File URL" --inputbox "Please insert the URL where backup files are stored." 10 60 "https://domain.com/backup-files.zip" 3>&1 1>&2 2>&3)
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    display --indent 6 --text "${source_files_url}"

  else
    return 1

  fi

  # File Backup details
  backup_file=${source_files_url##*/}

  # Log
  display --indent 6 --text "- Downloading file backup"
  log_event "info" "Downloading file backup ${source_files_url}" "false"
  log_event "debug" "Running: curl --silent -L ${source_files_url} >${BROLIT_TMP_DIR}/${project_domain}/${backup_file}" "false"

  # Create tmp dir structure
  mkdir -p "${BROLIT_TMP_DIR}"
  mkdir -p "${BROLIT_TMP_DIR}/${project_domain}"

  # Download File Backup
  curl --silent -L "${source_files_url}" >"${BROLIT_TMP_DIR}/${project_domain}/${backup_file}"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Log
    clear_previous_lines "1"
    display --indent 6 --text "- Downloading file backup" --result "DONE" --color GREEN

  else

    # Log
    log_event "error" "Download failed!" "false"
    display --indent 6 --text "- Downloading file backup" --result "FAIL" --color RED

    return 1

  fi

  # Uncompressing
  decompress "${BROLIT_TMP_DIR}/${project_domain}/${backup_file}" "${BROLIT_TMP_DIR}" "lbzip2"

  exitstatus=$?
  if [[ ${exitstatus} -eq 1 ]]; then

    # Log
    log_event "error" "Restore project aborted." "false"
    display --indent 8 --text "Restore project aborted"--tcolor RED

    return 1

  fi

  # Remove downloaded file
  rm --force "${BROLIT_TMP_DIR}/${project_domain}/${backup_file}"

  change_ownership "www-data" "www-data" "${PROJECTS_PATH}/${project_domain}"

  # Create database and user
  db_project_name=$(mysql_name_sanitize "${project_name}")

  database_name="${db_project_name}_${project_state}"
  database_user="${db_project_name}_user"
  database_user_passw=$(openssl rand -hex 12)

  mysql_database_create "${database_name}"
  mysql_user_create "${database_user}" "${database_user_passw}" "localhost"
  mysql_user_grant_privileges "${database_user}" "${database_name}" "localhost"

  # Search for .sql or sql.gz files
  local find_result

  # Find backups from downloaded ftp files
  find_result="$({
    find "${BROLIT_TMP_DIR}/${project_domain}" -name "*.sql"
    find "${BROLIT_TMP_DIR}/${project_domain}" -name "*.sql.gz"
  })"

  if [[ ${find_result} != "" ]]; then

    log_event "info" "Database backups found on downloaded files" "false"

    array_to_checklist "${find_result}"

    # Backup file selection
    chosen_database_backup="$(whiptail --title "DATABASE TO RESTORE" --checklist "Select the database backup you want to restore." 20 78 15 "${checklist_array[@]}" 3>&1 1>&2 2>&3)"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      # Restore database
      restore_database_backup "${project_name}" "${project_state}" "${chosen_database_backup}"

    else

      log_event "info" "Database backup selection skipped" "false"
      display --indent 6 --text "- Database backup selection" --result "SKIPPED" --color YELLOW

    fi

  else

    log_event "info" "No database backups found on downloaded files" "false"

    source_db_url=$(whiptail --title "Database URL" --inputbox "Please insert the URL where the database backup is stored." 10 60 "https://domain.com/backup-db.zip" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      # Database Backup details
      backup_file=${source_db_url##*/}

      # Download database backup
      curl --silent -L "${source_db_url}" >"${BROLIT_TMP_DIR}/${project_domain}/${backup_file}"

      # Restore database
      restore_database_backup "${project_name}" "${project_state}" "${backup_file}"

    else
      return 1

    fi

  fi

  # Move to ${PROJECTS_PATH}
  log_event "info" "Moving ${project_domain} to ${PROJECTS_PATH} ..." "false"
  mv "${BROLIT_TMP_DIR}/${project_domain}" "${PROJECTS_PATH}/${project_domain}"

  actual_folder="${PROJECTS_PATH}/${project_domain}"

  # Create nginx config files for site
  nginx_server_create "${project_domain}" "wordpress" "single"

  # Change DNS record
  if [[ ${SUPPORT_CLOUDFLARE_STATUS} == "enabled" ]]; then

    # TODO: Ask for subdomains to change in Cloudflare (root domain asked before)
    # SUGGEST "${project_domain}" and "www${project_domain}"

    # Cloudflare API to change DNS records
    cloudflare_set_record "${root_domain}" "${project_domain}" "A" "false" "${SERVER_IP}"

  fi

  # HTTPS with Certbot
  certbot_helper_installer_menu "${NOTIFICATION_EMAIL_MAILA}" "${project_domain}"

  project_type="$(project_get_type "${actual_folder}")"

  if [[ ${project_type} == "wordpress" ]]; then

    install_path="$(wp_config_path "${actual_folder}")"
    if [[ -z "${install_path}" ]]; then

      log_event "info" "WordPress installation found" "false"

      # Change file and dir permissions
      wp_change_permissions "${actual_folder}/${install_path}"

      # Change wp-config.php database parameters
      wp_update_wpconfig "${actual_folder}/${install_path}" "${project_name}" "${project_state}" "${database_user_passw}"

      # WP Search and Replace URL
      wp_ask_url_search_and_replace "${actual_folder}/${install_path}"

    fi

  fi

  # Create brolit_config.json file
  project_create_config "${actual_folder}/${install_path}" "${project_name}" "${project_state}" "${project_type}" "enabled" "mysql" "${database_name}" "localhost" "${database_user}" "${database_user_passw}" "${project_domain}" "" "" "true" ""

  # Remove tmp files
  log_event "info" "Removing temporary folders ..." "false"
  rm --force --recursive "${BROLIT_TMP_DIR}/${project_domain:?}"

  # Send notifications
  send_notification "✅ ${VPSNAME}" "Project ${project_name} restored!"

  HTMLOPEN='<html><body>'
  BODY_SRV_MIG='Migración finalizada en '${ELAPSED_TIME}'<br/>'
  BODY_DB='Database: '${project_name}'_'${project_state}'<br/>Database User: '${project_name}'_user <br/>Database User Pass: '${database_user_passw}'<br/>'
  HTMLCLOSE='</body></html>'

  mail_send_notification "✅ ${VPSNAME} - Project ${project_name} restored!" "${HTMLOPEN} ${BODY_SRV_MIG} ${BODY_DB} ${BODY_CLF} ${HTMLCLOSE}"

}

################################################################################
# Restore backup from dropbox (server selection)
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_backup_server_selection() {

  local dropbox_server_list # list servers directories on dropbox
  local chosen_server       # whiptail var

  # Select SERVER
  dropbox_server_list="$("${DROPBOX_UPLOADER}" -hq list "/" | awk '{print $2;}')"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Show dropbox output
    chosen_server="$(whiptail --title "RESTORE BACKUP" --menu "Choose a server to work with" 20 78 10 $(for x in ${dropbox_server_list}; do echo "${x} [D]"; done) 3>&1 1>&2 2>&3)"

    log_event "debug" "chosen_server: ${chosen_server}" "false"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      # List dropbox directories
      #dropbox_type_list="$(${DROPBOX_UPLOADER} -hq list "${chosen_server}" | awk '{print $2;}')"
      #dropbox_type_list='project '${dropbox_type_list}
      dropbox_type_list='project site database'

      # Select backup type
      restore_type_selection_from_dropbox "${chosen_server}" "${dropbox_type_list}"

    else

      restore_manager_menu

    fi

  else

    log_event "error" "Dropbox uploader failed. Output: ${dropbox_server_list}. Exit status: ${exitstatus}" "false"

  fi

  restore_manager_menu

}

################################################################################
# Restore database backup
#
# Arguments:
#   $1 = ${project_name}
#   $2 = ${project_state}
#   $3 = ${project_backup} - The backup file must be in ${BROLIT_TMP_DIR}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_database_backup() {

  local project_name=$1
  local project_state=$2
  local project_backup=$3

  local db_name
  local db_exists
  local user_db_exists
  local db_pass

  log_subsection "Restore Database Backup"

  db_name="${project_name}_${project_state}"

  # Check if database already exists
  mysql_database_exists "${db_name}"
  db_exists=$?
  if [[ ${db_exists} -eq 1 ]]; then
    # Create database
    mysql_database_create "${db_name}"

  else

    # Create temporary folder for backups
    if [[ ! -d "${BROLIT_TMP_DIR}/backups" ]]; then
      mkdir -p "${BROLIT_TMP_DIR}/backups"
      log_event "info" "Temp files directory created: ${BROLIT_TMP_DIR}/backups" "false"
    fi

    # Make backup of actual database
    log_event "info" "MySQL database ${db_name} already exists" "false"
    mysql_database_export "${db_name}" "${BROLIT_TMP_DIR}/backups/${db_name}_bk_before_restore.sql"

  fi

  # Restore database
  project_backup="${project_backup%%.*}.sql"
  mysql_database_import "${project_name}_${project_state}" "${BROLIT_TMP_DIR}/${project_backup}"

  if [[ ${exitstatus} -eq 0 ]]; then
    # Deleting temp files
    rm --force "${project_backup%%.*}.tar.bz2"
    rm --force "${project_backup}"

    # Log
    log_event "info" "Temp files cleanned" "false"
    display --indent 6 --text "- Cleanning temp files" --result "DONE" --color GREEN

    return 0

  else

    return 1

  fi

}

################################################################################
# Restore database backup
#
# Arguments:
#   $1 = ${dropbox_chosen_type_path}
#   $2 = ${dropbox_project_list}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_config_files_from_dropbox() {

  local dropbox_chosen_type_path=$1
  local dropbox_project_list=$2

  local chosen_config_type # whiptail var
  local dropbox_bk_list    # dropbox backup list
  local chosen_config_bk   # whiptail var

  log_subsection "Restore Server config Files"

  # Select config backup type
  chosen_config_type="$(whiptail --title "RESTORE CONFIGS BACKUPS" --menu "Choose a config backup type." 20 78 10 $(for x in ${dropbox_project_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)"
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then
    #Restore from Dropbox
    dropbox_bk_list="$(${DROPBOX_UPLOADER} -hq list "${dropbox_chosen_type_path}/${chosen_config_type}" | awk '{print $2;}')"
  fi

  chosen_config_bk="$(whiptail --title "RESTORE CONFIGS BACKUPS" --menu "Choose a config backup file to restore." 20 78 10 $(for x in ${dropbox_bk_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)"
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    #cd "${BROLIT_MAIN_DIR}/tmp"

    # Downloading Config Backup
    display --indent 6 --text "- Downloading config backup from dropbox"

    dropbox_download "${dropbox_chosen_type_path}/${chosen_config_type}/${chosen_config_bk}" "${BROLIT_MAIN_DIR}/tmp"
    #dropbox_output="$(${DROPBOX_UPLOADER} download "${dropbox_chosen_type_path}/${chosen_config_type}/${chosen_config_bk}" 1>&2)"

    clear_previous_lines "1"
    display --indent 6 --text "- Downloading config backup from dropbox" --result "DONE" --color GREEN

    # Restore files
    mkdir -p "${chosen_config_type}"
    mv "${chosen_config_bk}" "${chosen_config_type}"
    #cd "${chosen_config_type}"

    # Decompress
    decompress "${chosen_config_bk}" "${BROLIT_MAIN_DIR}/tmp/${chosen_config_type}" "lbzip2"

    if [[ "${chosen_config_bk}" == *"nginx"* ]]; then

      restore_nginx_site_files "" ""

    fi
    if [[ "${CHOSEN_CONFIG}" == *"mysql"* ]]; then
      log_event "info" "MySQL Config backup downloaded and uncompressed on  ${BROLIT_MAIN_DIR}/tmp/${chosen_config_type}"
      whiptail_message "IMPORTANT!" "MySQL config files were downloaded on this temp directory: ${BROLIT_MAIN_DIR}/tmp/${chosen_config_type}."

    fi
    if [[ "${CHOSEN_CONFIG}" == *"php"* ]]; then
      log_event "info" "PHP config backup downloaded and uncompressed on  ${BROLIT_MAIN_DIR}/tmp/${chosen_config_type}"
      whiptail_message "IMPORTANT!" "PHP config files were downloaded on this temp directory: ${BROLIT_MAIN_DIR}/tmp/${chosen_config_type}."

    fi
    if [[ "${CHOSEN_CONFIG}" == *"letsencrypt"* ]]; then
      log_event "info" "Let's Encrypt config backup downloaded and uncompressed on  ${BROLIT_MAIN_DIR}/tmp/${chosen_config_type}"
      whiptail_message "IMPORTANT!" "Let's Encrypt config files were downloaded on this temp directory: ${BROLIT_MAIN_DIR}/tmp/${chosen_config_type}."

    fi

    # TODO: ask for remove tmp files
    #echo " > Removing ${BROLIT_MAIN_DIR}/tmp/${chosen_type} ..." >>$LOG
    #echo -e ${GREEN}" > Removing ${BROLIT_MAIN_DIR}/tmp/${chosen_type} ..."${ENDCOLOR}
    #rm -R ${BROLIT_MAIN_DIR}/tmp/${chosen_type}

  fi

}

################################################################################
# Restore nginx site files
#
# Arguments:
#   $1 = ${domain}
#   $2 = ${date}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_nginx_site_files() {

  local domain=$1
  local date=$2

  local bk_file
  local bk_to_download
  local filename
  local to_restore
  local dropbox_output # var for dropbox output

  bk_file="nginx-configs-files-${date}.tar.bz2"
  bk_to_download="${chosen_server}/configs/nginx/${bk_file}"

  # Subsection
  log_subsection "Nginx Server Configuration Restore"

  # Downloading Config Backup
  log_event "info" "Downloading nginx backup from dropbox" "false"
  display --indent 6 --text "- Downloading nginx backup from dropbox"

  dropbox_output="$(${DROPBOX_UPLOADER} download "${bk_to_download}" 1>&2)"

  clear_previous_lines "1"
  display --indent 6 --text "- Downloading nginx backup from dropbox" --result "DONE" --color GREEN

  # Extract tar.bz2 with lbzip2
  mkdir -p "${BROLIT_MAIN_DIR}/tmp/nginx"
  decompress "${bk_file}" "${BROLIT_MAIN_DIR}/tmp/nginx" "lbzip2"

  # TODO: if nginx is installed, ask if nginx.conf must be replace

  # Checking if default nginx folder exists
  if [[ -n "${WSERVER}" ]]; then

    log_event "info" "Folder ${WSERVER} exists ... OK"

    if [[ -z "${domain}" ]]; then

      startdir="${BROLIT_MAIN_DIR}/tmp/nginx/sites-available"
      file_browser "$menutitle" "$startdir"

      to_restore=${filepath}"/"${filename}
      log_event "info" "File to restore: ${to_restore} ..."

    else

      to_restore="${BROLIT_MAIN_DIR}/tmp/nginx/sites-available/${domain}"
      filename=${domain}

      log_event "info" "File to restore: ${to_restore} ..."

    fi

    if [[ -f "${WSERVER}/sites-available/${filename}" ]]; then

      log_event "info" "File ${WSERVER}/sites-available/${filename} already exists. Making a backup file ..."
      mv "${WSERVER}/sites-available/${filename}" "${WSERVER}/sites-available/${filename}_bk"

      display --indent 6 --text "- Making backup of existing config" --result "DONE" --color GREEN

    fi

    log_event "info" "Restoring nginx configuration from backup: ${filename}"

    # Copy files
    cp "${to_restore}" "${WSERVER}/sites-available/${filename}"

    # Creating symbolic link
    ln -s "${WSERVER}/sites-available/${filename}" "${WSERVER}/sites-enabled/${filename}"

    #display --indent 6 --text "- Restoring Nginx server config" --result "DONE" --color GREEN
    #nginx_server_change_domain "${WSERVER}/sites-enabled/${filename}" "${domain}" "${domain}"

    nginx_configuration_test

  else

    log_event "error" "/etc/nginx/sites-available NOT exist... Skipping!"
    #echo "ERROR: nginx main dir is not present!"

  fi

}

################################################################################
# Restore letsencrypt files
#
# Arguments:
#   $1 = ${domain}
#   $2 = ${date}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_letsencrypt_site_files() {

  local domain=$1
  local date=$2

  local bk_file
  local bk_to_download

  bk_file="letsencrypt-configs-files-${date}.tar.bz2"
  bk_to_download="${chosen_server}/configs/letsencrypt/${bk_file}"

  log_event "debug" "Running: ${DROPBOX_UPLOADER} download ${bk_to_download}"

  dropbox_output=$(${DROPBOX_UPLOADER} download "${bk_to_download}" 1>&2)

  # Extract tar.bz2 with lbzip2
  log_event "info" "Extracting ${bk_file} on ${BROLIT_MAIN_DIR}/tmp/"

  mkdir "${BROLIT_MAIN_DIR}/tmp/letsencrypt"
  decompress "${bk_file}" "${BROLIT_MAIN_DIR}/tmp/letsencrypt" "lbzip2"

  # Creating directories
  if [[ ! -d "/etc/letsencrypt/archive/" ]]; then
    mkdir "/etc/letsencrypt/archive/"

  fi
  if [[ ! -d "/etc/letsencrypt/live/" ]]; then
    mkdir "/etc/letsencrypt/live/"

  fi
  if [[ ! -d "/etc/letsencrypt/archive/${domain}" ]]; then
    mkdir "/etc/letsencrypt/archive/${domain}"

  fi
  if [[ ! -d "/etc/letsencrypt/live/${domain}" ]]; then
    mkdir "/etc/letsencrypt/live/${domain}"

  fi

  # Check if file exist
  if [[ ! -f "/etc/letsencrypt/options-ssl-nginx.conf" ]]; then
    cp -r "${BROLIT_MAIN_DIR}/tmp/letsencrypt/options-ssl-nginx.conf" "/etc/letsencrypt/"

  fi
  if [[ ! -f "/etc/letsencrypt/ssl-dhparams.pem" ]]; then
    cp -r "${BROLIT_MAIN_DIR}/tmp/letsencrypt/ssl-dhparams.pem" "/etc/letsencrypt/"

  fi

  # TODO: Restore main files (checking non-www and www domains)
  if [[ ! -f "${BROLIT_MAIN_DIR}/tmp/letsencrypt/archive/${domain}" ]]; then
    cp -r "${BROLIT_MAIN_DIR}/tmp/letsencrypt/archive/${domain}" "/etc/letsencrypt/archive/"

  fi
  if [[ ! -f "${BROLIT_MAIN_DIR}/tmp/letsencrypt/live/${domain}" ]]; then
    cp -r "${BROLIT_MAIN_DIR}/tmp/letsencrypt/live/${domain}" "/etc/letsencrypt/live/"

  fi

  display --indent 6 --text "- Restoring letsencrypt config files" --result "DONE" --color GREEN

}

################################################################################
# Restore site files
#
# Arguments:
#   $1 = ${domain}
#   $2 = ${backup_path}
#   $3 = ${path_to_restore}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

# TODO: refactor to accept domain, backup_file, path_to_restore

function restore_backup_files() {

  local domain=$1
  #local backup_path=$2
  #local path_to_restore=$3

  local actual_folder
  local folder_to_install
  local chosen_domain

  log_subsection "Restore Files Backup"

  chosen_domain="$(whiptail --title "Project Domain" --inputbox "Want to change the project's domain? Default:" 10 60 "${domain}" 3>&1 1>&2 2>&3)"
  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Log
    log_event "info" "Working with domain: ${chosen_domain}"
    display --indent 6 --text "- Selecting project domain" --result "DONE" --color GREEN
    display --indent 8 --text "${chosen_domain}" --tcolor YELLOW

    # If user change project domains, we need to do this
    project_tmp_old_folder="${BROLIT_TMP_DIR}/${domain}"
    project_tmp_new_folder="${BROLIT_TMP_DIR}/${chosen_domain}"

    # Renaming
    if [[ ${project_tmp_old_folder} != "${project_tmp_new_folder}" ]]; then
      mv "${project_tmp_old_folder}" "${project_tmp_new_folder}"
    fi

    # Ask folder to install
    #folder_to_install="$(ask_folder_to_install_sites "${PROJECTS_PATH}")"

    # New destination directory
    actual_folder="${PROJECTS_PATH}/${chosen_domain}"

    # Check if destination folder exist
    if [[ -d ${actual_folder} ]]; then

      # If exists, make a backup
      _make_temp_files_backup "${actual_folder}"

    fi

    # Restore files
    move_files "${project_tmp_new_folder}" "${PROJECTS_PATH}"

    # Change ownership
    change_ownership "www-data" "www-data" "${actual_folder}"

    # Return
    echo "${chosen_domain}"

  else

    return 1

  fi

}

################################################################################
# Restore type selection from dropbox
#
# Arguments:
#   $1 = ${chosen_server}
#   $2 = ${dropbox_type_list}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_type_selection_from_dropbox() {

  local chosen_server=$1
  local dropbox_type_list=$2

  local chosen_type                # whiptail var
  local chosen_backup_to_restore   # whiptail var
  local dropbox_chosen_type_path   # whiptail var
  local dropbox_project_list       # list of projects on dropbox directory
  local dropbox_chosen_backup_path # whiptail var
  local dropbox_backup_list        # dropbox listing directories
  local domain                     # extracted domain
  local db_project_name            # extracted db name
  local bk_to_dowload              # backup to download
  local folder_to_install          # directory to install project
  local project_site               # project site

  chosen_type="$(whiptail --title "RESTORE FROM BACKUP" --menu "Choose a backup type. You can choose restore an entire project or only site files, database or config." 20 78 10 $(for x in ${dropbox_type_list}; do echo "${x} [D]"; done) 3>&1 1>&2 2>&3)"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    log_subsection "Restore ${chosen_type} Backup"

    dropbox_status_list="online offline"

    chosen_status="$(whiptail --title "RESTORE FROM BACKUP" --menu "Choose a backup status." 20 78 10 $(for x in ${dropbox_status_list}; do echo "${x} [D]"; done) 3>&1 1>&2 2>&3)"

    if [[ ${chosen_type} == "project" ]]; then

      restore_project "${chosen_server}" "${chosen_status}"

    elif [[ ${chosen_type} != "project" ]]; then

      dropbox_chosen_type_path="${chosen_server}/projects-${chosen_status}/${chosen_type}"

      dropbox_project_list="$("${DROPBOX_UPLOADER}" -hq list "${dropbox_chosen_type_path}" | awk '{print $2;}')"

      if [[ ${chosen_type} == *"configs"* ]]; then

        restore_config_files_from_dropbox "${dropbox_chosen_type_path}" "${dropbox_project_list}"

      else # DB or SITE

        # Select Project
        chosen_project="$(whiptail --title "RESTORE BACKUP" --menu "Choose Backup Project" 20 78 10 $(for x in ${dropbox_project_list}; do echo "$x [D]"; done) 3>&1 1>&2 2>&3)"
        exitstatus=$?
        if [[ ${exitstatus} -eq 0 ]]; then
          dropbox_chosen_backup_path="${dropbox_chosen_type_path}/${chosen_project}"
          dropbox_backup_list="$("${DROPBOX_UPLOADER}" -hq list "${dropbox_chosen_backup_path}" | awk '{print $3;}')"

        fi
        # Select Backup File
        chosen_backup_to_restore="$(whiptail --title "RESTORE BACKUP" --menu "Choose Backup to Download" 20 78 10 $(for x in ${dropbox_backup_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)"
        exitstatus=$?
        if [[ ${exitstatus} -eq 0 ]]; then

          # Asking project state with suggested actual state
          suffix=${chosen_project%_*} ## strip the tail
          project_state="$(ask_project_state "${suffix}")"

          # Asking project name
          project_name="$(ask_project_name "${possible_project_name}")"

          # Sanitize ${project_name}
          db_project_name="$(mysql_name_sanitize "${project_name}")"

          project_backup_date="$(backup_get_date "${chosen_backup_to_restore}")"
          bk_to_dowload="${dropbox_chosen_type_path}/${chosen_project}/${chosen_backup_to_restore}"

          # Downloading Backup
          dropbox_download "${bk_to_dowload}" "${BROLIT_TMP_DIR}"

          # Decompress
          decompress "${BROLIT_TMP_DIR}/${chosen_backup_to_restore}" "${BROLIT_TMP_DIR}" "lbzip2"

          if [[ ${chosen_type} == *"database"* ]]; then

            # Restore Database Backup
            restore_backup_database "${db_project_name}" "${project_state}" "${project_backup_date}"

            # TODO: ask if want to change project db parameters and make cloudflare changes

            # TODO: check project type (WP, Laravel, etc)

            folder_to_install="$(ask_folder_to_install_sites "${PROJECTS_PATH}")"
            folder_to_install_result=$?
            if [[ ${folder_to_install_result} -eq 1 ]]; then

              return 0

            fi

            startdir="${folder_to_install}"
            menutitle="Site Selection Menu"
            directory_browser "${menutitle}" "${startdir}"

            directory_browser_result=$?
            if [[ ${directory_browser_result} -eq 1 ]]; then

              return 0

            fi

            project_site=$filepath"/"$filename
            install_path="$(wp_config_path "${folder_to_install}/${filename}")"

            if [[ "${install_path}" != "" ]]; then

              # Select wordpress installation to work with
              project_path="$(wordpress_select_project_to_work_with "${install_path}")"

              log_event "info" "WordPress installation found: ${project_path}" "false"

              # Change wp-config.php database parameters
              wp_update_wpconfig "${project_path}" "${project_name}" "${project_state}" "${db_pass}"

              # Change Salts
              wpcli_set_salts "${project_path}"

              # Change URLs
              wp_ask_url_search_and_replace "${project_path}"

              # Changing wordpress visibility
              if [[ ${project_state} == "prod" ]]; then

                wpcli_change_wp_seo_visibility "${project_path}" "1"

              else

                wpcli_change_wp_seo_visibility "${project_path}" "0"

              fi

            else

              log_event "error" "WordPress installation not found" "false"

            fi

          else
            # site

            # At this point chosen_project is the new project domain
            restore_backup_files "${chosen_project}"

          fi

        fi

      fi

    fi

  fi

}

################################################################################
# Restore project
#
# Arguments:
#   $1 = ${chosen_server}
#   $2 = ${chosen_status} - online or offline
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function restore_project() {

  local chosen_server=$1
  local chosen_status=$2

  local dropbox_project_list
  local chosen_project
  local dropbox_chosen_backup_path
  local dropbox_backup_list
  local bk_to_dowload
  local chosen_backup_to_restore
  local db_to_download
  local project_db_status

  log_section "Restore Project Backup"

  # TODO: what if project is not a site? Maybe is a database-only project.

  # Get dropbox folders list
  dropbox_project_list="$(${DROPBOX_UPLOADER} -hq list "${chosen_server}/projects-${chosen_status}/site" | awk '{print $2;}')"

  # Select Project
  chosen_project="$(whiptail --title "RESTORE PROJECT BACKUP" --menu "Choose a project backup to restore:" 20 78 10 $(for x in ${dropbox_project_list}; do echo "$x [D]"; done) 3>&1 1>&2 2>&3)"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # Get dropbox backup list
    dropbox_chosen_backup_path="${chosen_server}/projects-${chosen_status}/site/${chosen_project}"
    dropbox_backup_list="$("${DROPBOX_UPLOADER}" -hq list "${dropbox_chosen_backup_path}" | awk '{print $3;}')"

  else

    display --indent 2 --text "- Restore project backup" --result "SKIPPED" --color YELLOW

    return 1

  fi

  # Select Backup File
  chosen_backup_to_restore="$(whiptail --title "RESTORE PROJECT BACKUP" --menu "Choose Backup to Download" 20 78 10 $(for x in ${dropbox_backup_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    display --indent 6 --text "- Selecting project backup" --result "DONE" --color GREEN
    display --indent 8 --text "${chosen_backup_to_restore}" --tcolor YELLOW

    # Download backup
    bk_to_dowload="${chosen_server}/projects-${chosen_status}/site/${chosen_project}/${chosen_backup_to_restore}"
    dropbox_download "${bk_to_dowload}" "${BROLIT_TMP_DIR}"

    # Decompress
    decompress "${BROLIT_TMP_DIR}/${chosen_backup_to_restore}" "${BROLIT_TMP_DIR}" "lbzip2"

    # Create nginx.conf file if not exists
    touch "${BROLIT_TMP_DIR}/nginx.conf"

    # Project Type
    project_type="$(project_get_type "${BROLIT_TMP_DIR}/${chosen_project}")"

    log_event "debug" "Project Type: ${project_type}" "false"

    # Here, for convention, chosen_project should be CHOSEN_DOMAIN...
    # Only for better code reading, i assign this new var:
    chosen_domain="${chosen_project}"

    # Restore site files
    new_project_domain="$(restore_backup_files "${chosen_domain}")"

    # Extract project name from domain
    possible_project_name="$(project_get_name_from_domain "${new_project_domain}")"

    # Asking project state with suggested actual state
    suffix=${chosen_project%_*} ## strip the tail
    project_state="$(ask_project_state "${suffix}")"

    # Asking project name
    project_name="$(ask_project_name "${possible_project_name}")"

    display --indent 8 --text "Project Type ${project_type}" --tcolor GREEN

    # Reading config file
    if [[ ${project_type} != "html" ]]; then
      # Database vars
      db_engine="$(project_get_configured_database_engine "${BROLIT_TMP_DIR}/${chosen_project}" "${project_type}")"
      db_name="$(project_get_configured_database "${BROLIT_TMP_DIR}/${chosen_project}" "${project_type}")"
      db_user="$(project_get_configured_database_user "${BROLIT_TMP_DIR}/${chosen_project}" "${project_type}")"
      db_pass="$(project_get_configured_database_userpassw "${BROLIT_TMP_DIR}/${chosen_project}" "${project_type}")"
      # Sanitize ${project_name}
      db_project_name="$(mysql_name_sanitize "${project_name}")"
    fi

    install_path="${PROJECTS_PATH}/${new_project_domain}"

    if [[ -n ${db_name} ]]; then

      # Database Backup
      project_backup_date="$(backup_get_date "${chosen_backup_to_restore}")"
      db_to_download="${chosen_server}/projects-${chosen_status}/database/${db_name}/${db_name}_database_${project_backup_date}.tar.bz2"
      db_to_restore="${BROLIT_TMP_DIR}/${db_name}_database_${project_backup_date}.tar.bz2"

      # Log
      log_event "debug" "Project database selected: ${chosen_project}" "false"
      log_event "debug" "Backup date: ${project_backup_date}" "false"

      # Downloading Database Backup
      dropbox_download "${db_to_download}" "${BROLIT_TMP_DIR}"

      exitstatus=$?
      if [[ ${exitstatus} -eq 1 ]]; then

        # TODO: ask to download manually calling restore_database_backup or skip database restore part
        whiptail_message_with_skip_option "RESTORE BACKUP" "Database backup not found. Do you want to select manually the database backup to restore?"

        exitstatus=$?
        if [[ ${exitstatus} -eq 0 ]]; then

          # Get dropbox backup list
          dropbox_chosen_backup_path="${chosen_server}/projects-${chosen_status}/database/${chosen_project}"
          dropbox_backup_list="$("${DROPBOX_UPLOADER}" -hq list "${dropbox_chosen_backup_path}" | awk '{print $3;}')"

          # Select Backup File
          chosen_backup_to_restore="$(whiptail --title "RESTORE BACKUP" --menu "Choose Backup to Download" 20 78 10 $(for x in ${dropbox_backup_list}; do echo "$x [F]"; done) 3>&1 1>&2 2>&3)"
          exitstatus=$?
          if [[ ${exitstatus} -eq 0 ]]; then

            # Decompress
            decompress "${db_to_restore}" "${BROLIT_TMP_DIR}" "lbzip2"

            # Restore Database Backup
            restore_backup_database "${db_name}" "${project_state}" "${project_backup_date}"

            project_db_status="enabled"

          fi

        else

          display --indent 2 --text "- Restore project backup" --result "SKIPPED" --color YELLOW

          return 1

        fi

      else

        # Decompress
        decompress "${db_to_restore}" "${BROLIT_TMP_DIR}" "lbzip2"

        # Restore Database Backup
        restore_backup_database "${db_name}" "${project_state}" "${project_backup_date}"

        project_db_status="enabled"

      fi

    else

      # TODO: ask to download manually calling restore_database_backup or skip database restore part
      project_db_status="disabled"

    fi

    possible_root_domain="$(get_root_domain "${new_project_domain}")"
    root_domain="$(ask_root_domain "${possible_root_domain}")"

    # TODO: if ${new_project_domain} == ${chosen_domain}, maybe ask if want to restore nginx and let's encrypt config files
    # restore_letsencrypt_site_files "${chosen_domain}" "${project_backup_date}"
    # restore_nginx_site_files "${chosen_domain}" "${project_backup_date}"

    if [[ ${new_project_domain} == "${root_domain}" || ${new_project_domain} == "www.${root_domain}" ]]; then

      # Nginx config
      nginx_server_create "www.${root_domain}" "${project_type}" "root_domain" "${root_domain}"

      if [[ ${SUPPORT_CLOUDFLARE_STATUS} == "enabled" ]]; then

        # Cloudflare API
        # TODO: must check for CNAME with www
        cloudflare_set_record "${root_domain}" "${root_domain}" "A" "false" "${SERVER_IP}"

      fi

      # Let's Encrypt
      certbot_certificate_install "${NOTIFICATION_EMAIL_MAILA}" "${root_domain},www.${root_domain}"

      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then

        nginx_server_add_http2_support "${root_domain}"

      fi

    else

      # TODO: remove hardcoded parameter "single"

      # Nginx config
      nginx_server_create "${new_project_domain}" "${project_type}" "single"

      if [[ ${SUPPORT_CLOUDFLARE_STATUS} == "enabled" ]]; then

        # Cloudflare API
        cloudflare_set_record "${root_domain}" "${new_project_domain}" "A" "false" "${SERVER_IP}"

      fi

      # Let's Encrypt
      certbot_certificate_install "${NOTIFICATION_EMAIL_MAILA}" "${new_project_domain}"

      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then

        nginx_server_add_http2_support "${new_project_domain}"

      fi

    fi

    # TODO: create brolit_project_conf.json file with project info
    project_create_config "${PROJECTS_PATH}/${chosen_domain}" "${chosen_project}" "${project_state}" "${project_type}" "${project_db_status}" "${db_engine}" "${db_name}" "${db_user}" "${db_pass}" "${new_project_domain}"

    # TODO: make a function of this on wordpress helper
    #wordpress_post_install_tasks ""

    # Check if is a WP project
    if [[ ${project_type} == "wordpress" ]]; then

      wp_change_permissions "${install_path}"

      # Change wp-config.php database parameters
      wp_update_wpconfig "${install_path}" "${db_project_name}" "${project_state}" "${db_pass}"

      # Change urls on database
      # TODO: non protocol before domains (need to check if http or https before)?
      if [[ ${chosen_domain} != "${new_project_domain}" ]]; then

        # Change urls on database
        wpcli_search_and_replace "${install_path}" "${chosen_domain}" "${new_project_domain}"

      fi

      # Shuffle salts
      wpcli_set_salts "${install_path}"

      # Changing wordpress visibility
      if [[ ${project_state} == "prod" ]]; then
        wpcli_change_wp_seo_visibility "${install_path}" "1"

      else
        wpcli_change_wp_seo_visibility "${install_path}" "0"

      fi

    fi

    # Send notification
    send_notification "✅ ${VPSNAME}" "Project ${new_project_domain} restored!"

  fi

}

function restore_backup_database() {

  local project_name="${1}"
  local project_state="${2}"
  local project_backup_date="${3}"

  # Restore database function
  restore_database_backup "${db_project_name}" "${project_state}" "${db_name}_database_${project_backup_date}.tar.bz2"

  # Database parameters
  db_name="${db_project_name}_${project_state}"
  db_user="${db_project_name}_user"

  # Check if user database already exists
  mysql_user_exists "${db_user}"
  user_db_exists=$?
  if [[ ${user_db_exists} -eq 0 ]]; then

    # Passw generator
    db_pass="$(openssl rand -hex 12)"
    # Create database user with autogenerated pass
    mysql_user_create "${db_user}" "${db_pass}" "localhost"

  else

    # Log
    log_event "warning" "MySQL user ${db_user} already exists" "false"
    display --indent 6 --text "- Creating ${db_user} user in MySQL" --result "FAIL" --color RED
    display --indent 8 --text "MySQL user ${db_user} already exists."

    whiptail_message "WARNING" "MySQL user ${db_user} already exists. Please after the script ends, check project configuration files."

  fi

  # Grant privileges to database user
  mysql_user_grant_privileges "${db_user}" "${db_name}" "localhost"

}
