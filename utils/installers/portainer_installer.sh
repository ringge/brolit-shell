#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha7
################################################################################
#
# Portainer Installer
#
################################################################################

################################################################################
# Portainer install
#
# Arguments:
#   none
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function portainer_installer() {

    log_subsection "Portainer Installer"

    package_update

    package_install_if_not "docker.io"
    package_install_if_not "docker-compose"

    # Check if portainer is running
    portainer="$(docker_get_container_id "portainer")"
    if [[ -z ${portainer} ]]; then

        docker volume create portainer_data

        docker run -d -p "${PACKAGES_PORTAINER_CONFIG_PORT}":"${PACKAGES_PORTAINER_CONFIG_PORT}" --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest

        exitstatus=$?
        if [[ ${exitstatus} -eq 0 ]]; then

            PACKAGES_PORTAINER_STATUS="enabled"

            json_write_field "${BROLIT_CONFIG_FILE}" "PACKAGES.portainer[].status" "${PACKAGES_GRAFANA_STATUS}"

            # new global value ("enabled")
            export PACKAGES_PORTAINER_STATUS

            return 0

        else

            return 1

        fi

    else
        log_event "warning" "Portainer is already installed" "false"
    fi

}

################################################################################
# Portainer purge/remove
#
# Arguments:
#   none
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function portainer_purge() {

    log_subsection "Portainer Installer"

    # Get Portainer Container ID
    container_id="$(docker ps | grep portainer | awk '{print $1;}')"

    # Stop Portainer Container
    docker stop "${container_id}"

    # Remove Portainer Container
    docker rm -f portainer

    # Remove Portainer Volume
    volume rm portainer_data

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        PACKAGES_PORTAINER_STATUS="disabled"

        json_write_field "${BROLIT_CONFIG_FILE}" "PACKAGES.portainer[].status" "${PACKAGES_PORTAINER_STATUS}"

        # new global value ("disabled")
        export PACKAGES_PORTAINER_STATUS

        return 0

    else

        return 1

    fi

}

################################################################################
# Configure Portainer service
#
# Arguments:
#   none
#
# Outputs:
#   0 if it utils were installed, 1 on error.
################################################################################

function portainer_configure() {

    log_event "info" "Configuring portainer ..."

    # TODO: if is nginx installed, then create nginx server and proxy portainer

    # Check if firewall is enabled
    if [ "$(ufw status | grep -c "Status: active")" -eq "1" ]; then
        firewall_allow "${PACKAGES_PORTAINER_CONFIG_PORT}"
    fi

    nginx_server_create "${PACKAGES_PORTAINER_CONFIG_SUBDOMAIN}" "portainer"

    # Replace port on nginx server config
    sed -i "s/PORTAINER_PORT/${PACKAGES_PORTAINER_CONFIG_PORT}/g" "${WSERVER}/sites-available/${PACKAGES_PORTAINER_CONFIG_SUBDOMAIN}"

    # Log
    display --indent 6 --text "- Portainer configuration" --result "DONE" --color GREEN
    log_event "info" "Portainer configured" "false"

}
