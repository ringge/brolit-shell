#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha8
#############################################################################
#
# Backup Helper: Perform backup actions.
#
################################################################################

################################################################################
# Get Backup Date
#
# Arguments:
#  $1 = ${backup_file}
#
# Outputs:
#   ${backup_date}
################################################################################

function backup_get_date() {

  local backup_file=$1

  local backup_date

  backup_date="$(echo "${backup_file}" | grep -Eo '[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}')"

  # Return
  echo "${backup_date}"

}

################################################################################
# Make server files Backup
#
# Arguments:
#  $1 = ${bk_type} - Backup Type: configs, logs, data
#  $2 = ${bk_sup_type} - Backup SubType: php, nginx, mysql
#  $3 = ${bk_path} - Path folder to Backup
#  $4 = ${directory_to_backup} - Folder to Backup
#
# Outputs:
#   0 if ok, 1 if error
################################################################################

function backup_server_config() {

  # TODO: need to implement error_type

  local bk_type=$1
  local bk_sup_type=$2
  local bk_path=$3
  local directory_to_backup=$4

  local got_error
  local backup_file
  local old_bk_file
  local dropbox_path

  got_error=0

  if [[ -n ${bk_path} ]]; then

    # Backups file names
    backup_file="${bk_sup_type}-${bk_type}-files-${NOW}.tar.bz2"
    old_bk_file="${bk_sup_type}-${bk_type}-files-${DAYSAGO}.tar.bz2"

    # Log
    display --indent 6 --text "- Files backup for ${YELLOW}${bk_sup_type}${ENDCOLOR}"
    log_event "info" "Files backup for : ${bk_sup_type}" "false"

    # Compress backup
    backup_file_size="$(compress "${bk_path}" "${directory_to_backup}" "${BROLIT_TMP_DIR}/${NOW}/${backup_file}")"

    # Check test result
    compress_result=$?
    if [[ ${compress_result} -eq 0 ]]; then

      # Log
      clear_previous_lines "1"
      display --indent 6 --text "- Files backup for ${YELLOW}${bk_sup_type}${ENDCOLOR}" --result "DONE" --color GREEN
      display --indent 8 --text "Final backup size: ${YELLOW}${backup_file_size}${ENDCOLOR}"

      # Remote Path
      remote_path="${VPSNAME}/server-config/${bk_type}/${bk_sup_type}"

      # Create folder structure
      storage_create_dir "${VPSNAME}"
      storage_create_dir "${VPSNAME}/server-config"
      storage_create_dir "${VPSNAME}/server-config/${bk_sup_type}"

      # Uploading backup files
      storage_upload_backup "${BROLIT_TMP_DIR}/${NOW}/${backup_file}" "${remote_path}"

      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then

        # Deleting old backup file
        storage_delete_backup "${remote_path}/${old_bk_file}"

        # Deleting tmp backup file
        rm --force "${BROLIT_TMP_DIR}/${NOW}/${backup_file}"

        # Return
        echo "${backup_file_size}"

      fi

    else

      # Log
      clear_previous_lines "1"
      display --indent 6 --text "- Files backup for ${YELLOW}${bk_sup_type}${ENDCOLOR}" --result "FAIL" --color RED

      error_msg="Something went wrong making a backup of ${directory_to_backup}."
      error_type=""
      got_error=1

      # Return
      echo "${got_error}"

    fi

  else

    log_event "error" "Directory ${bk_path} doesn't exists." "false"

    display --indent 6 --text "- Creating backup file" --result "FAIL" --color RED
    display --indent 8 --text "Result: Directory '${bk_path}' doesn't exists" --tcolor RED

    error_msg="Directory ${bk_path} doesn't exists."
    error_type=""
    got_error=1

    # Return
    echo "${got_error}"

  fi

  log_break "true"

}

################################################################################
# Make all server configs Backup
#
# Arguments:
#  none
#
# Outputs:
#   0 if ok, 1 if error
################################################################################

function backup_all_server_configs() {

  #local -n backuped_config_list
  #local -n backuped_config_sizes_list

  local backuped_config_index=0

  log_subsection "Backup Server Config"

  # TAR Webserver Config Files
  if [[ ! -d ${WSERVER} ]]; then
    log_event "warning" "WSERVER is not defined! Skipping webserver config files backup ..." "false"

  else
    nginx_files_backup_result="$(backup_server_config "configs" "nginx" "${WSERVER}" ".")"

    backuped_config_list[$backuped_config_index]="${WSERVER}"
    backuped_config_sizes_list+=("${nginx_files_backup_result}")

    backuped_config_index=$((backuped_config_index + 1))

  fi

  # TAR PHP Config Files
  if [[ ! -d ${PHP_CF} ]]; then
    log_event "warning" "PHP_CF is not defined! Skipping PHP config files backup ..." "false"

  else

    php_files_backup_result="$(backup_server_config "configs" "php" "${PHP_CF}" ".")"

    backuped_config_list[$backuped_config_index]="${PHP_CF}"
    backuped_config_sizes_list+=("${php_files_backup_result}")

    backuped_config_index=$((backuped_config_index + 1))

  fi

  # TAR MySQL Config Files
  if [[ ! -d ${MYSQL_CF} ]]; then
    log_event "warning" "MYSQL_CF is not defined! Skipping MySQL config files backup ..." "false"

  else

    mysql_files_backup_result="$(backup_server_config "configs" "mysql" "${MYSQL_CF}" ".")"

    backuped_config_list[$backuped_config_index]="${MYSQL_CF}"
    backuped_config_sizes_list+=("${mysql_files_backup_result}")

    backuped_config_index=$((backuped_config_index + 1))

  fi

  # TAR Let's Encrypt Config Files
  if [[ ! -d ${LENCRYPT_CF} ]]; then
    log_event "warning" "LENCRYPT_CF is not defined! Skipping Letsencrypt config files backup ..." "false"

  else

    le_files_backup_result="$(backup_server_config "configs" "letsencrypt" "${LENCRYPT_CF}" ".")"

    backuped_config_list[$backuped_config_index]="${LENCRYPT_CF}"
    backuped_config_sizes_list+=("${le_files_backup_result}")

    backuped_config_index=$((backuped_config_index + 1))

  fi

  # TAR Devops Config Files
  if [[ ! -d ${BROLIT_CONFIG_PATH} ]]; then
    log_event "warning" "BROLIT_CONFIG_PATH is not defined! Skipping DevOps config files backup ..." "false"

  else

    brolit_files_backup_result="$(backup_server_config "configs" "brolit" "${BROLIT_CONFIG_PATH}" ".")"

    backuped_config_list[$backuped_config_index]="${BROLIT_CONFIG_PATH}"
    backuped_config_sizes_list+=("${brolit_files_backup_result}")

    backuped_config_index=$((backuped_config_index + 1))

  fi

  # Configure Files Backup Section for Email Notification
  mail_config_backup_section "${ERROR}" "${ERROR_MSG}" "${backuped_config_list[@]}" "${backuped_config_sizes_list[@]}"

  # Return
  echo "${ERROR}"

}

################################################################################
# Make Mailcow Backup
#
# Arguments:
#  $1 = ${directory_to_backup} - Path folder to Backup
#
# Outputs:
#   0 if ok, 1 if error
################################################################################

function backup_mailcow() {

  local directory_to_backup=$1

  # VAR $bk_type rewrited
  local bk_type="mailcow"
  local mailcow_backup_result
  local dropbox_path

  log_subsection "Mailcow Backup"

  if [[ -n "${MAILCOW_DIR}" ]]; then

    old_bk_file="${bk_type}_files-${DAYSAGO}.tar.bz2"
    backup_file="${bk_type}_files-${NOW}.tar.bz2"

    log_event "info" "Trying to make a backup of ${MAILCOW_DIR} ..." "false"
    display --indent 6 --text "- Making ${YELLOW}${MAILCOW_DIR}${ENDCOLOR} backup" --result "DONE" --color GREEN

    # Small hack for pass backup directory to backup_and_restore.sh
    MAILCOW_BACKUP_LOCATION="${MAILCOW_DIR}"
    export MAILCOW_BACKUP_LOCATION

    # Run built-in script for backup Mailcow
    "${MAILCOW_DIR}/helper-scripts/backup_and_restore.sh" backup all
    mailcow_backup_result=$?
    if [[ ${mailcow_backup_result} -eq 0 ]]; then

      # Small trick to get Mailcow backup base dir
      cd "${MAILCOW_DIR}"
      cd mailcow-*

      # New MAILCOW_BACKUP_LOCATION
      MAILCOW_BACKUP_LOCATION="$(basename "${PWD}")"

      # Back
      cd ..

      log_event "info" "Making tar.bz2 from: ${MAILCOW_DIR}/${MAILCOW_BACKUP_LOCATION} ..." "false"

      # Tar file
      (${TAR} -cf - --directory="${MAILCOW_DIR}" "${MAILCOW_BACKUP_LOCATION}" | pv --width 70 -ns "$(du -sb "${MAILCOW_DIR}/${MAILCOW_BACKUP_LOCATION}" | awk '{print $1}')" | lbzip2 >"${MAILCOW_TMP_BK}/${backup_file}")

      # Log
      clear_previous_lines "1"
      log_event "info" "Testing backup file: ${backup_file} ..." "false"

      # Test backup file
      lbzip2 --test "${MAILCOW_TMP_BK}/${backup_file}"

      lbzip2_result=$?
      if [[ ${lbzip2_result} -eq 0 ]]; then

        log_event "info" "${MAILCOW_TMP_BK}/${backup_file} backup created" "false"

        # New folder with $VPSNAME
        dropbox_create_dir "${VPSNAME}"
        dropbox_create_dir "${VPSNAME}/${bk_type}"

        dropbox_path="/${VPSNAME}/projects-online/${bk_type}"

        log_event "info" "Uploading Backup to Dropbox ..." "false"
        display --indent 6 --text "- Uploading backup file to Dropbox"

        # Upload new backup
        dropbox_upload "${MAILCOW_TMP_BK}/${backup_file}" "${dropbox_path}"

        # Remove old backup
        dropbox_delete "${dropbox_path}/${old_bk_file}"

        # Remove old backups from server
        rm --recursive --force "${MAILCOW_DIR}/${MAILCOW_BACKUP_LOCATION:?}"
        rm --recursive --force "${MAILCOW_TMP_BK}/${backup_file:?}"

        log_event "info" "Mailcow backup finished" "false"

      fi

    else

      log_event "error" "Can't make the backup!" "false"

      return 1

    fi

  else

    log_event "error" "Directory '${MAILCOW_DIR}' doesnt exists!" "false"

    return 1

  fi

  log_break "true"

}

################################################################################
# Make sites files Backup
#
# Arguments:
#  none
#
# Outputs:
#   0 if ok, 1 if error
################################################################################

function backup_all_projects_files() {

  local backup_file_size

  local backuped_files_index=0
  local backuped_directory_index=0

  local directory_name=""

  local k=0

  log_subsection "Backup Sites Files"

  # Get all directories
  TOTAL_SITES="$(get_all_directories "${PROJECTS_PATH}")"

  # Get length of $TOTAL_SITES
  COUNT_TOTAL_SITES="$(find "${PROJECTS_PATH}" -maxdepth 1 -type d -printf '.' | wc -c)"
  COUNT_TOTAL_SITES="$((COUNT_TOTAL_SITES - 1))"

  # Log
  display --indent 6 --text "- Directories found" --result "${COUNT_TOTAL_SITES}" --color WHITE
  log_event "info" "Found ${COUNT_TOTAL_SITES} directories" "false"
  log_break "true"

  for j in ${TOTAL_SITES}; do

    log_event "info" "Processing [${j}] ..." "false"

    if [[ ${k} -gt 0 ]]; then

      directory_name="$(basename "${j}")"

      if [[ ${BLACKLISTED_SITES} != *"${directory_name}"* ]]; then

        backup_file_size="$(backup_project_files "site" "${PROJECTS_PATH}" "${directory_name}")"

        backuped_files_list[$backuped_files_index]="${directory_name}"
        backuped_files_sizes_list+=("${backup_file_size}")
        backuped_files_index=$((backuped_files_index + 1))

        log_break "true"

      else
        log_event "info" "Omitting ${directory_name} (blacklisted) ..." "false"

      fi

      backuped_directory_index=$((backuped_directory_index + 1))

      log_event "info" "Processed ${backuped_directory_index} of ${COUNT_TOTAL_SITES} directories" "false"

    fi

    k=$k+1

  done

  # Deleting old backup files
  rm --recursive --force "${BROLIT_TMP_DIR:?}/${NOW}"

  # DUPLICITY
  backup_duplicity

  # Configure Files Backup Section for Email Notification
  mail_files_backup_section "${ERROR}" "${ERROR_MSG}" "${backuped_files_list[@]}" "${backuped_files_sizes_list[@]}"

}

################################################################################
# Make all files Backup
#
# Arguments:
#  none
#
# Outputs:
#  0 if ok, 1 if error
################################################################################

function backup_all_files() {

  ## MAILCOW FILES
  if [[ ${MAILCOW_BK} == true ]]; then

    if [[ ! -d ${MAILCOW_TMP_BK} ]]; then

      log_event "info" "Folder ${MAILCOW_TMP_BK} doesn't exist. Creating now ..." "false"

      mkdir -p "${MAILCOW_TMP_BK}"

    fi

    backup_mailcow "${MAILCOW}"

  fi

  ## SERVER CONFIG FILES
  backup_all_server_configs

  ## PROJECTS_PATH FILES
  backup_all_projects_files

}

################################################################################
# Make files Backup
#
# Arguments:
#  $1 = ${bk_type} - Backup Type (site_configs or sites)
#  $2 = ${bk_path} - Path where directories to backup are stored
#  $3 = ${directory_to_backup} - The specific folder/file to backup
#
# Outputs:
#  0 if ok, 1 if error
################################################################################

function backup_project_files() {

  local bk_type=$1
  local bk_path=$2
  local directory_to_backup=$3

  local old_bk_file="${directory_to_backup}_${bk_type}-files_${DAYSAGO}.tar.bz2"
  local backup_file="${directory_to_backup}_${bk_type}-files_${NOW}.tar.bz2"

  local dropbox_path

  # Create directory structure
  storage_create_dir "${VPSNAME}"
  storage_create_dir "${VPSNAME}/projects-online"
  storage_create_dir "${VPSNAME}/projects-online/${bk_type}"
  storage_create_dir "${VPSNAME}/projects-online/${bk_type}/${directory_to_backup}"

  remote_path="${VPSNAME}/projects-online/${bk_type}/${directory_to_backup}"

  if [[ ${BACKUP_DROPBOX_STATUS} == "enabled" || ${BACKUP_SFTP_STATUS} == "enabled" ]]; then

    # Log
    display --indent 6 --text "- Files backup for ${YELLOW}${directory_to_backup}${ENDCOLOR}"
    log_event "info" "Files backup for : ${directory_to_backup}" "false"

    # Compress backup
    backup_file_size="$(compress "${bk_path}" "${directory_to_backup}" "${BROLIT_TMP_DIR}/${NOW}/${backup_file}")"

    # Check test result
    compress_result=$?
    if [[ ${compress_result} -eq 0 ]]; then

      # Log
      clear_previous_lines "1"
      display --indent 6 --text "- Files backup for ${YELLOW}${directory_to_backup}${ENDCOLOR}" --result "DONE" --color GREEN
      display --indent 8 --text "Final backup size: ${YELLOW}${backup_file_size}${ENDCOLOR}"

      log_event "info" "Backup ${BROLIT_TMP_DIR}/${NOW}/${backup_file} created, final size: ${backup_file_size}" "false"

      # Upload backup
      storage_upload_backup "${BROLIT_TMP_DIR}/${NOW}/${backup_file}" "${remote_path}"

      exitstatus=$?
      if [[ ${exitstatus} -eq 0 ]]; then

        # Delete old backup from Dropbox
        storage_delete_backup "${remote_path}/${old_bk_file}"

        # Delete temp backup
        rm --force "${BROLIT_TMP_DIR}/${NOW}/${backup_file}"

        # Log
        log_event "info" "Temp backup deleted from server" "false"

        # Return
        echo "${backup_file_size}"

      fi

    else

      # Log
      clear_previous_lines "1"
      display --indent 6 --text "- Files backup for ${directory_to_backup}" --result "FAIL" --color RED

      return 1

    fi

  fi

  if [[ ${BACKUP_LOCAL_STATUS} == "enabled" ]]; then

    storage_upload_backup "${bk_path}/${directory_to_backup}" "${remote_path}"

  fi

}

################################################################################
# Duplicity Backup (BETA)
#
# Arguments:
#  none
#
# Outputs:
#   0 if ok, 1 if error
################################################################################

function backup_duplicity() {

  if [[ ${BACKUP_DUPLICITY_STATUS} == "enabled" ]]; then

    log_event "warning" "duplicity backup is in BETA state" "true"

    # Check if DUPLICITY is installed
    package_install_if_not "duplicity"

    # Get all directories
    all_sites="$(get_all_directories "${PROJECTS_PATH}")"

    # Loop in to Directories
    #for i in $(echo "${PROJECTS_PATH}" | sed "s/,/ /g"); do
    for i in ${all_sites}; do

      log_event "debug" "Running: duplicity --full-if-older-than \"${BACKUP_DUPLICITY_CONFIG_BACKUP_FREQUENCY}\" -v4 --no-encryption\" ${PROJECTS_PATH}\"\"${i}\" file://\"${BACKUP_DUPLICITY_CONFIG_BACKUP_DESTINATION_PATH}\"\"${i}\"" "true"

      duplicity --full-if-older-than "${BACKUP_DUPLICITY_CONFIG_BACKUP_FREQUENCY}" -v4 --no-encryption" ${PROJECTS_PATH}""${i}" file://"${BACKUP_DUPLICITY_CONFIG_BACKUP_DESTINATION_PATH}""${i}"
      exitstatus=$?

      log_event "debug" "exitstatus=$?" "false"

      # TODO: should only remove old entries only if ${exitstatus} -eq 0
      duplicity remove-older-than "${BACKUP_DUPLICITY_CONFIG_FULL_LIFE}" --force "${BACKUP_DUPLICITY_CONFIG_BACKUP_DESTINATION_PATH}"/"${i}"

    done

    [ $exitstatus -eq 0 ] && echo "*** DUPLICITY SUCCESS ***" >>"${LOG}"
    [ $exitstatus -ne 0 ] && echo "*** DUPLICITY ERROR ***" >>"${LOG}"

  fi

}

################################################################################
# Make all databases Backup
#
# Arguments:
#  none
#
# Outputs:
#  0 if ok, 1 if error
################################################################################

function backup_all_databases() {

  local got_error
  local error_msg
  local error_type
  local database_backup_index

  # Starting Messages
  log_subsection "Backup Databases"

  if [[ ${PACKAGES_MARIADB_STATUS} != "enabled" ]] && [[ ${PACKAGES_MYSQL_STATUS} != "enabled" ]] && [[ ${PACKAGES_POSTGRES_STATUS} != "enabled" ]]; then

    display --indent 6 --text "- Initializing database backup script" --result "SKIPPED" --color YELLOW
    display --indent 8 --text "No database engine present on server" --tcolor YELLOW
    return 1

  fi

  display --indent 6 --text "- Initializing database backup script" --result "DONE" --color GREEN

  if [[ ${PACKAGES_MARIADB_STATUS} == "enabled" ]] || [[ ${PACKAGES_MYSQL_STATUS} == "enabled" ]]; then

    # Get MySQL DBS
    mysql_databases="$(mysql_list_databases "all")"

    # Count MySQL databases
    databases_count="$(mysql_count_databases "${mysql_databases}")"

    # Log
    display --indent 6 --text "- MySql databases found" --result "${databases_count}" --color WHITE
    log_event "info" "MySql databases found: ${databases_count}" "false"
    log_break "true"

    # Loop in to MySQL Databases and make backup
    backup_databases "${mysql_databases}" "mysql"

    backup_databases_status=$?
    if [[ ${backup_databases_status} -eq 1 ]]; then

      got_error="true"
      error_msg="${error_msg}${error_msg:+\n}MySQL backup failed"
      error_type="${error_type}${error_type:+\n}MySQL"

    fi

  fi

  if [[ ${PACKAGES_POSTGRES_STATUS} == "enabled" ]]; then

    # Get PostgreSQL DBS
    psql_databases="$(postgres_list_databases "all")"

    # Count PostgreSQL databases
    databases_count="$(postgres_count_databases "${psql_databases}")"

    # Log
    display --indent 6 --text "- PSql databases found" --result "${databases_count}" --color WHITE
    log_event "info" "PSql databases found: ${databases_count}" "false"
    log_break "true"

    # Loop in to PostgreSQL Databases and make backup
    backup_databases "${psql_databases}" "psql"

    backup_databases_status=$?
    if [[ ${backup_databases_status} -eq 1 ]]; then

      got_error="true"
      error_msg="${error_msg}${error_msg:+\n}PostgreSQL backup failed"
      error_type="${error_type}${error_type:+\n}PostgreSQL"

    fi

  fi

  return 0

}

################################################################################
# Make databases backup
#
# Arguments:
#  $1 = ${databases}
#  $2 = ${db_engine}
#
# Outputs:
#  0 if ok, 1 if error
################################################################################

function backup_databases() {

  local databases=$1
  local db_engine=$2

  local got_error=0
  local database_backup_index=0

  for database in ${databases}; do

    if [[ ${BLACKLISTED_DATABASES} != *"${database}"* ]]; then

      log_event "info" "Processing [${database}] ..." "false"

      # Make database backup
      backup_file="$(backup_project_database "${database}" "${db_engine}")"

      if [[ ${backup_file} != "" ]]; then

        # Extract parameters from ${backup_file}
        database_backup_path="$(echo "${backup_file}" | cut -d ";" -f 1)"
        database_backup_size="$(echo "${backup_file}" | cut -d ";" -f 2)"

        database_backup_file="$(basename "${database_backup_path}")"

        backuped_databases_list[$database_backup_index]="${database_backup_file}"
        backuped_databases_sizes_list+=("${database_backup_size}")

        exitstatus=$?
        if [[ ${exitstatus} -eq 0 ]]; then

          # Old backup
          old_backup_file="${database}_database_${DAYSAGO}.tar.bz2"

          # Delete old backup from Dropbox
          storage_delete_backup "/${VPSNAME}/projects-online/database/${database}/${old_backup_file}"

          exitstatus=$?
          if [[ ${exitstatus} -eq 0 ]]; then

            # Delete temp backup
            rm --force "${BROLIT_TMP_DIR}/${NOW}/${database_backup_path}"

            # Log
            log_event "info" "${BROLIT_TMP_DIR}/${NOW}/${database_backup_path} backup deleted from server." "false"

            # Return
            # echo "${database_backup_size}"

          fi

        fi

        database_backup_index=$((database_backup_index + 1))

        log_event "info" "Backup ${database_backup_index} of ${databases_count} done" "false"

      else

        #error_type=""
        got_error=1

        log_event "error" "Something went wrong making a backup of ${database}." "false"

      fi

    else

      display --indent 6 --text "- Ommiting database ${database}" --result "DONE" --color WHITE
      log_event "info" "Ommiting blacklisted database: ${database}" "false"

    fi

    log_break "true"

  done

  # Configure Email
  mail_databases_backup_section "${error_msg}" "${error_type}" "${backuped_databases_list[@]}" "${backuped_databases_sizes_list[@]}"

  # Return
  return ${got_error}

}

################################################################################
# Make database Backup
#
# Arguments:
#  $1 = ${database}
#
# Outputs:
#  "backupfile backup_file_size" if ok, 1 if error
################################################################################

function backup_project_database() {

  local database=$1
  local db_engine=$2

  local export_result

  local directory_to_backup="${BROLIT_TMP_DIR}/${NOW}/"
  local db_file="${database}_database_${NOW}.sql"

  local backup_file="${database}_database_${NOW}.tar.bz2"

  log_event "info" "Creating new database backup of '${database}'" "false"

  if [[ ${db_engine} == "mysql" ]]; then
    # Create dump file
    mysql_database_export "${database}" "${directory_to_backup}${db_file}"
  else

    if [[ ${db_engine} == "psql" ]]; then
      # Create dump file
      postgres_database_export "${database}" "${directory_to_backup}${db_file}"
    fi

  fi

  export_result=$?
  if [[ ${export_result} -eq 0 ]]; then

    # Compress backup
    backup_file_size="$(compress "${directory_to_backup}" "${db_file}" "${BROLIT_TMP_DIR}/${NOW}/${backup_file}")"

    # Check test result
    compress_result=$?
    if [[ ${compress_result} -eq 0 ]]; then

      # Log
      display --indent 8 --text "Final backup size: ${YELLOW}${backup_file_size}${ENDCOLOR}"

      # Create dir structure
      storage_create_dir "/${VPSNAME}/projects-online"
      storage_create_dir "/${VPSNAME}/projects-online/database"
      storage_create_dir "/${VPSNAME}/projects-online/database/${database}"

      # Upload database backup
      storage_upload_backup "${BROLIT_TMP_DIR}/${NOW}/${backup_file}" "/${VPSNAME}/projects-online/database/${database}"

      upload_result=$?
      if [[ ${upload_result} -eq 0 ]]; then

        rm --force "${directory_to_backup}/${db_file}"

        # Return
        ## output format: backupfile backup_file_size
        echo "${BROLIT_TMP_DIR}/${NOW}/${backup_file};${backup_file_size}"

        return 0

      fi

    else

      return 1

    fi

  else

    ERROR=true
    ERROR_MSG="Error creating dump file for database: ${database}"
    log_event "error" "${ERROR_MSG}" "false"

    return 1

  fi

}

################################################################################
# Make project Backup
#
# Arguments:
#  $1 = ${project_domain}
#  $2 = ${backup_type} - (all,configs,sites,databases) - Default: all
#
# Outputs:
#   0 if ok, 1 if error
################################################################################

function backup_project() {

  local project_domain=$1
  local backup_type=$2

  local project_name
  local project_config_file

  # Backup files
  backup_file_size="$(backup_project_files "site" "${PROJECTS_PATH}" "${project_domain}")"

  exitstatus=$?
  if [[ ${exitstatus} -eq 0 ]]; then

    # TODO: Check others project types

    log_event "info" "Trying to get database name from project ..." "false"

    project_name="$(project_get_name_from_domain "${project_domain}")"

    project_config_file="${BROLIT_CONFIG_PATH}/${project_name}_conf.json"

    if [[ -f "${project_config_file}" ]]; then

      project_type="$(project_get_config "${project_config_file}" "project[].type")"
      db_name="$(project_get_configured_database "${BROLIT_TMP_DIR}/${project_name}" "${project_type}")"
      db_engine="$(project_get_configured_database_engine "${BROLIT_TMP_DIR}/${project_name}" "${project_type}")"

    else

      #db_engine="$(project_get_configured_database_engine "${BROLIT_TMP_DIR}/${project_name}" "${project_type}")"
      db_stage="$(project_get_stage_from_domain "${project_domain}")"
      db_name="$(project_get_name_from_domain "${project_domain}")"
      db_name="${db_name}_${db_stage}"

    fi

    # TODO: check database engine
    mysql_database_exists "${db_name}"
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      # Backup database
      backup_project_database "${db_name}" "mysql"

    else

      # Log
      log_event "info" "Database ${db_name} not found" "false"
      display --indent 6 --text "Database backup" --result "SKIPPED" --color YELLOW
      display --indent 8 --text "Database ${db_name} not found" --tcolor YELLOW

    fi

    log_event "info" "Deleting backup from server ..." "false"

    rm --recursive --force "${BROLIT_TMP_DIR}/${NOW}/${backup_type:?}"

    log_event "info" "Project backup done" "false"

  else

    ERROR=true
    log_event "error" "Something went wrong making a project backup" "false"

  fi

}
