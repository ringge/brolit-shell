#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha2
################################################################################

### Main dir check
SFOLDER=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SFOLDER=$(cd "$(dirname "${SFOLDER}")" && pwd)
if [ -z "${SFOLDER}" ]; then
  exit 1 # error; the path is not accessible
fi

# shellcheck source=${SFOLDER}/libs/commons.sh
source "${SFOLDER}/libs/commons.sh"

################################################################################

# Running from cron
log_event "info" "Running uptime_tasks.sh from cron ..." "false"

# Script Initialization
script_init "true"

#Log
log_section "Uptime Checker"

# Get all directories
all_sites="$(get_all_directories "${PROJECTS_PATH}")"

## Get length of $all_sites
count_all_sites=$(find "${PROJECTS_PATH}" -maxdepth 1 -type d -printf '.' | wc -c)
count_all_sites=$((count_all_sites - 1))

log_event "info" "Found ${count_all_sites} directories" "false"
display --indent 2 --text "- Directories found" --result "${count_all_sites}" --color YELLOW

# GLOBALS
keyword="wp-content"
file_index=0
#BK_FL_ARRAY_INDEX=0
#declare -a BACKUPED_LIST

# Folder blacklist
blacklist=".wp-cli,phpmyadmin,html"

k=0

for site in ${all_sites}; do

  if [[ "$k" -gt 0 ]]; then

    project_name="$(basename "${site}")"

    if [[ ${blacklist} != *"${project_name}"* ]]; then

      log_event "info" "Project name: ${project_name}" "false"

      curl --silent -L "${project_name}" 2>&1 | grep -q "${keyword}"
      curl_output=$?

      if [[ ${curl_output} == 0 ]]; then

        log_event "info" "Website ${project_name} is online" "false"
        display --indent 2 --text "- Testing ${project_name}" --result "UP" --color GREEN

      else

        log_event "error" "Website ${project_name} is offline" "false"
        display --indent 2 --text "- Testing ${project_name}" --result "DOWN" --color RED

        # Send notification
        send_notification "⛔ ${VPSNAME}" "Website ${project_name} is offline"

      fi

    else

      log_event "error" "Found ${project_name} on blacklist, skipping ..." "false"

    fi

  fi

  k=$k+1

done

# Running scripts
#"${SFOLDER}/utils/server_and_image_optimizations.sh"

#DB_MAIL="${TMP_DIR}/db-bk-${NOW}.mail"
#DB_MAIL_VAR=$(<"${DB_MAIL}")

#ONFIG_MAIL="${TMP_DIR}/config-bk-${NOW}.mail"
#CONFIG_MAIL_VAR=$(<"${CONFIG_MAIL}")

#FILE_MAIL="${TMP_DIR}/file-bk-${NOW}.mail"
#FILE_MAIL_VAR=$(<"${FILE_MAIL}")

#MAIL_FOOTER=$(mail_footer "${SCRIPT_V}")

# Checking result status for mail subject
#EMAIL_STATUS=$(mail_subject_status "${STATUS_BACKUP_DBS}" "${STATUS_BACKUP_FILES}" "${STATUS_SERVER}" "${OUTDATED_PACKAGES}")

# Preparing email to send
#log_event "info" "Sending Email to ${NOTIFICATION_EMAIL_MAILA} ..." "true"

#EMAIL_SUBJECT="${EMAIL_STATUS} on ${VPSNAME} Complete Backup - [${NOWDISPLAY}]"
#EMAIL_CONTENT="${HTMLOPEN} ${BODY_SRV} ${PKG_MAIL_VAR} ${CERT_MAIL_VAR} ${CONFIG_MAIL_VAR} ${DB_MAIL_VAR} ${FILE_MAIL_VAR} ${MAIL_FOOTER}"

# Sending email notification
#mail_send_notification "${EMAIL_SUBJECT}" "${EMAIL_CONTENT}"
