#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha5
################################################################################

### Main dir check
BROLIT_MAIN_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BROLIT_MAIN_DIR=$(cd "$(dirname "${BROLIT_MAIN_DIR}")" && pwd)
if [[ -z "${BROLIT_MAIN_DIR}" ]]; then
    exit 1 # error; the path is not accessible
fi

# shellcheck source=${BROLIT_MAIN_DIR}/libs/commons.sh
source "${BROLIT_MAIN_DIR}/libs/commons.sh"

################################################################################

# Script Initialization
script_init "true"

# Check needed packages
package_install_security_utils

# Running from cron
log_event "info" "Running security_tasks.sh ..." "false"

log_section "Security Tasks"

# Clamav Scan
clamscan_result="$(security_clamav_scan "${PROJECTS_PATH}")"

if [[ ${clamscan_result} == "true" ]]; then

    send_notification "⚠️ ${VPSNAME}" "Clamav found malware files! Please check result file on server." ""

fi

## Commented this, too many false positives

# Custom Scan
#custom_scan_result="$(security_custom_scan "${PROJECTS_PATH}")"
#if [[ ${custom_scan_result} != "" ]]; then
#
#    send_notification "⚠️ ${VPSNAME}" "Custom scan result: ${custom_scan_result}" ""
#
#fi

# Script cleanup
cleanup

# Log End
log_event "info" "SECURITY TASKS SCRIPT End -- $(date +%Y%m%d_%H%M)" "false"
