#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha3
################################################################################
#
# Docker Helper: Perform docker actions.
#
################################################################################

################################################################################
# Get docker version.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_version() {

    package_is_installed "docker"

    exitstatus=$?
    if [[ "${exitstatus}" -eq 0 ]]; then

        docker_version="$(docker version --format '{{.Server.Version}}')"
        echo "${docker_version}"

        return 0
    else

        return 1

    fi

}

################################################################################
# List docker containers.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_list_containers() {

    package_is_installed "docker"

    exitstatus=$?
    if [[ "${exitstatus}" -eq 0 ]]; then

        # List docker containers.
        docker_containers="$(docker ps -a --format '{{.Names}}')"
        echo "${docker_containers}"

        return 0

    else

        return 1

    fi

}

################################################################################
# Stop docker container.
#
# Arguments:
#   $1 = ${container_to_stop}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_stop_container() {

    local container_to_stop="${1}"

    package_is_installed "docker"

    exitstatus=$?
    if [[ "${exitstatus}" -eq 0 ]]; then

        # Stop docker container.
        docker_stop_container="$(docker stop "${container_to_stop}")"
        echo "${docker_stop_container}"

        return 0

    else

        return 1

    fi

}

################################################################################
# List docker images.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_list_images() {

    package_is_installed "docker"

    exitstatus=$?
    if [[ "${exitstatus}" -eq 0 ]]; then

        # Docker list images
        docker_images="$(docker images --format '{{.Repository}}:{{.Tag}}')"
        echo "${docker_images}"

        return 0

    else

        return 1

    fi

}

################################################################################
# Docker delete image.
#
# Arguments:
#   $1 = ${image_to_delete}
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_delete_image() {

    local image_to_delete="${1}"

    package_is_installed "docker"

    exitstatus=$?
    if [[ "${exitstatus}" -eq 0 ]]; then

        # Docker delete image
        docker_delete_image="$(docker rmi "${image_to_delete}")"
        echo "${docker_delete_image}"

        return 0

    else

        return 1

    fi

}

################################################################################
# Docker system prune.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

function docker_system_prune() {

    echo "Docker system prune: $(docker system prune)"

}

################################################################################
# Docker WordPress install.
#
# Arguments:
#   none
#
# Outputs:
#   0 if ok, 1 on error.
################################################################################

# TODO: maybe it should be better use docker-compose

function docker_wordpress_install() {

    local docker_image="wordpress:latest"
    local docker_port="8088"
    #local php_version="7.4"

    local wordpress_database_host="localhost"
    local wordpress_database_name="wordpress"
    local wordpress_database_user="wordpress"
    local wordpress_database_password="wordpress"
    local wordpress_database_prefix="wp_"

    local wordpress_user="wordpress"
    local wordpress_user_password="wordpress"
    local wordpress_user_email="wordpress@localhost"

    # Docker run
    docker run --name wordpress -d -p "${docker_port}":80 -e WORDPRESS_DB_HOST="${wordpress_database_host}" -e WORDPRESS_DB_NAME="${wordpress_database_name}" -e WORDPRESS_DB_USER="${wordpress_database_user}" -e WORDPRESS_DB_PASSWORD="${wordpress_database_password}" -e WORDPRESS_DB_PREFIX="${wordpress_database_prefix}" -e WORDPRESS_USER="${wordpress_user}" -e WORDPRESS_USER_PASSWORD="${wordpress_user_password}" -e WORDPRESS_USER_EMAIL="${wordpress_user_email}" "${docker_image}"

    # Docker logs
    #docker logs wordpress

}
