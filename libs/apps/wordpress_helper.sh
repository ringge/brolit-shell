#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha1
################################################################################
#
# WordPress Helper: Perform wordpress actions.
#
################################################################################

################################################################################
# Check if is a WordPress project
#
# Arguments:
#  None
#
# Outputs:
#  0 if ok, 1 on error.
################################################################################

function is_wp_project() {

  # $1 = project directory

  local project_dir=$1

  local is_wp="false"

  log_event "info" "Checking if ${project_dir} is a WordPress project ..." "false"

  # Check if it has wp-config.php
  if [[ -f "${project_dir}/wp-config.php" ]]; then

    is_wp="true"
    log_event "info" "${project_dir} is a WordPress project" "false"

    # Return
    echo "${is_wp}"

  else

    log_event "info" "${project_dir} is not a WordPress project" "false"

    return 1

  fi

}

################################################################################
# WordPress config path
#
# Arguments:
#  $1 = ${dir_to_search}
#
# Outputs:
#  String with wp-config path
################################################################################

function wp_config_path() {

  local dir_to_search=$1

  # Log
  log_event "info" "Searching WordPress Installation on directory: ${dir_to_search}" "false"

  # Find where wp-config.php is
  find_output="$(find "${dir_to_search}" -name "wp-config.php" | sed 's|/[^/]*$||')"

  if [[ ${find_output} != "" ]]; then

    # Return
    echo "${find_output}"

    return 0

  else

    return 1

  fi

}

################################################################################
# Update WordPress config
#
# Arguments:
#  $1 = ${project_dir}
#  $2 = ${wp_project_name}
#  $3 = ${wp_project_state}
#  $4 = ${db_user_pass}
#
# Outputs:
#  String with wp-config path
################################################################################

#TODO: why not use https://developer.wordpress.org/cli/commands/config/create/ ?
function wp_update_wpconfig() {

  local wp_project_dir=$1
  local wp_project_name=$2
  local wp_project_state=$3
  local db_user_pass=$4

  local sed_output

  # Change wp-config.php database parameters
  log_event "info" "Changing database parameters on ${wp_project_dir}/wp-config.php" "false"

  sed -i "/DB_HOST/s/'[^']*'/'localhost'/2" "${wp_project_dir}/wp-config.php"

  if [[ ${wp_project_name} != "" ]]; then

    sed_output="$(sed -i "/DB_NAME/s/'[^']*'/'${wp_project_name}_${wp_project_state}'/2" "${wp_project_dir}/wp-config.php")"

  fi
  if [[ ${db_user_pass} != "" ]]; then

    sed_output="$(sed -i "/DB_USER/s/'[^']*'/'${wp_project_name}_user'/2" "${wp_project_dir}/wp-config.php")"
    sed_output="$(sed -i "/DB_PASSWORD/s/'[^']*'/'${db_user_pass}'/2" "${wp_project_dir}/wp-config.php")"

  fi

  sed_result=$?
  if [[ ${sed_result} -eq 0 ]]; then

    display --indent 6 --text "- Changing database parameters on wp-config.php" --result "DONE" --color GREEN

    return 0

  else

    display --indent 6 --text "- Changing database parameters on wp-config.php" --result "FAIL" --color RED
    display --indent 8 --text "Output: ${sed_output}" --tcolor RED

    return 1

  fi

}

################################################################################
# Change WordPress permissions
#
# Arguments:
#  $1 = ${project_dir}
#
# Outputs:
#  None
################################################################################

# TODO: check this ref: https://stackoverflow.com/questions/18352682/correct-file-permissions-for-wordpress

function wp_change_permissions() {

  local project_dir=$1

  # Change ownership
  change_ownership "www-data" "www-data" "${project_dir}"

  find "${project_dir}" -type d -exec chmod g+s {} \;

  if [[ -d "${project_dir}/wp-content" ]]; then

    chmod g+w "${project_dir}/wp-content"
    chmod -R g+w "${project_dir}/wp-content/themes"
    chmod -R g+w "${project_dir}/wp-content/plugins"

  fi

  log_event "info" "Permissions changes for: ${project_dir}" "false"
  display --indent 6 --text "- Setting default permissions on wordpress" --result "DONE" --color GREEN

}

################################################################################
# Replace string on WordPress database (without wp-cli)
#
# Arguments:
#  $1 = ${db_prefix}
#  $2 = ${target_db}
#
# Outputs:
#  None
################################################################################

# Ref multisite: https://multilingualpress.org/docs/wordpress-multisite-database-tables/
#
#UPDATE ${db_prefix}${blog_id}_blogs SET domain='${domain}' WHERE blog_id='1';
#UPDATE ${db_prefix}${blog_id}_blogs SET domain='${domain}' WHERE blog_id='2';
#
#UPDATE ${db_prefix}options SET option_value='${new_URL}' WHERE option_id='1';
#UPDATE ${db_prefix}options SET option_value='${new_URL}' WHERE option_id='2';
#
#UPDATE ${db_prefix}${blog_id}_site SET domain='${domain}' WHERE id='1'; #${domain} instead of ${new_URL}
#
#UPDATE ${db_prefix}${blog_id}_sitemeta SET meta_value='${new_URL}' WHERE meta_id='14';
#
#UPDATE ${db_prefix}${blog_id}_options SET option_value='${new_URL}' WHERE option_id='1';
#UPDATE ${db_prefix}${blog_id}_options SET option_value='${new_URL}' WHERE option_id='2';

function wp_replace_string_on_database() {

  local db_prefix=$1
  local target_db=$2
  local existing_URL=$3
  local new_URL=$4

  local chosen_db
  #local databases

  if [[ -z "${db_prefix}" ]]; then

    db_prefix="$(whiptail --title "WordPress DB Prefix" --inputbox "Please insert the WordPress Database Prefix. Example: wp_" 10 60 3>&1 1>&2 2>&3)"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      log_event "info" "Setting db prefix: '${db_prefix}'" "false"

    else

      return 1

    fi

  fi

  if [[ -z "${target_db}" ]]; then

    chosen_db="$(mysql_ask_database_selection)"

  else
    chosen_db="${target_db}"

  fi

  if [[ -n "${existing_URL}" && -n "${new_URL}" ]]; then

    #mysql_database_export "${chosen_db}" "${chosen_db}_bk_before_replace_urls.sql"

    # Queries
    SQL0="USE ${chosen_db};"
    SQL1="UPDATE ${db_prefix}options SET option_value = replace(option_value, '${existing_URL}', '${new_URL}') WHERE option_name = 'home' OR option_name = 'siteurl';"
    SQL2="UPDATE ${db_prefix}posts SET post_content = replace(post_content, '${existing_URL}', '${new_URL}');"
    SQL3="UPDATE ${db_prefix}posts SET guid = replace(guid, '${existing_URL}', '${new_URL}');"
    SQL4="UPDATE ${db_prefix}postmeta SET meta_value = replace(meta_value,'${existing_URL}','${new_URL}');"
    SQL5="UPDATE ${db_prefix}usermeta SET meta_value = replace(meta_value, '${existing_URL}','${new_URL}');"
    SQL6="UPDATE ${db_prefix}links SET link_url = replace(link_url, '${existing_URL}','${new_URL}');"
    SQL7="UPDATE ${db_prefix}comments SET comment_content = replace(comment_content , '${existing_URL}','${new_URL}');"

    log_event "info" "Replacing URLs in database ${chosen_db} ..." "false"

    "${MYSQL_ROOT}" -e "${SQL0}${SQL1}${SQL2}${SQL3}${SQL4}${SQL5}${SQL6}${SQL7}"

    exitstatus=$?
    if [[ $exitstatus -eq 0 ]]; then

        # Log
        log_event "info" "Search and replace finished ok" "false"
        display --indent 6 --text "- Running search and replace" --result "DONE" --color GREEN
        display --indent 8 --text "${existing_URL} was replaced by ${new_URL}"

    else

        # Log
        log_event "error" "Something went wrong running search and replace!" "false"
        display --indent 6 --text "- Running search and replace" --result "FAIL" --color RED

        return 1

    fi

  fi

}

################################################################################
# Ask string to replace on WordPress database
#
# Arguments:
#  $1 = ${wp_path}
#
# Outputs:
#  None
################################################################################

# TODO: need rethink this function
function wp_ask_url_search_and_replace() {

  local wp_path=$1

  local existing_URL
  local new_URL

  if [[ -z "${existing_URL}" ]]; then

    existing_URL="$(whiptail --title "URL TO CHANGE" --inputbox "Insert the URL you want to change, including http:// or https://" 10 60 3>&1 1>&2 2>&3)"
    exitstatus=$?

    if [[ ${exitstatus} -eq 0 ]]; then

      if [[ -z "${new_URL}" ]]; then

        new_URL="$(whiptail --title "THE NEW URL" --inputbox "Insert the new URL , including http:// or https://" 10 60 3>&1 1>&2 2>&3)"
        exitstatus=$?

        if [[ ${exitstatus} -eq 0 ]]; then

          # Create temporary folder for backups
          if [[ ! -d "${TMP_DIR}/backups" ]]; then
            mkdir "${TMP_DIR}/backups"
            log_event "info" "Temp files directory created: ${TMP_DIR}/backups" "false"
          fi

          project_name="$(basename "${wp_path}")"

          wpcli_export_database "${wp_path}" "${TMP_DIR}/backups/${project_name}_bk_before_search_and_replace.sql"

          wpcli_search_and_replace "${wp_path}" "${existing_URL}" "${new_URL}"

          exitstatus=$?

          # If wp-cli method fails, it will try to replace via SQL Query
          if [[ ${exitstatus} -eq 1 ]]; then

            # Get database and database prefix from wp-config.php
            db_prefix="$(cat "${wp_path}"/wp-config.php | grep "\$table_prefix" | cut -d \' -f 2)"
            target_db="$(sed -n "s/define( *'DB_NAME', *'\([^']*\)'.*/\1/p" "${wp_path}"/wp-config.php)"

            wp_replace_string_on_database "${db_prefix}" "${target_db}" "${existing_URL}" "${new_URL}"

          fi

        else

          display --indent 6 --text "- Configuring search and replace" --result "SKIPPED" --color YELLOW

        fi

      fi

    else

      display --indent 6 --text "- Configuring search and replace" --result "SKIPPED" --color YELLOW

    fi

  fi

}

function wordpress_select_project_to_work_with() {

  local wordpress_projects=$1

  # Get length of ${wordpress_projects} array
  len=${#wordpress_projects[@]}

  if [[ $len != 1 ]]; then

    local chosen_wordpress_project

    chosen_wordpress_project="$(whiptail --title "Project Selection" --menu "Select the project you want to work with:" 20 78 10 $(for x in ${wordpress_projects}; do echo "${x} [X]"; done) 3>&1 1>&2 2>&3)"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

      log_event "info" "Working with ${chosen_wordpress_project}" "false"

      # Return
      echo "${chosen_wordpress_project}"

    else

      log_event "debug" "Project selection skipped" "false"

      return 1

    fi

  else

    # Return
    echo "${wordpress_projects}"

  fi

}
