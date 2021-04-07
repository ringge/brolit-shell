#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.21
################################################################################
#
#   Ref: https://api.cloudflare.com/
#
################################################################################

function _cloudflare_get_zone_id() {

    # $1 = ${zone_name}

    local zone_name=$1

    local zone_id

    #zone_name="${root_domain}"

    # We need to do this, because certbot use this file with this vars
    # And this script need this others var names
    auth_email="${dns_cloudflare_email}"
    auth_key="${dns_cloudflare_api_key}"

    # Checking cloudflare credentials file
    if [[ -z "${auth_email}" ]]; then
        generate_cloudflare_config

    fi

    # Log
    display --indent 6 --text "- Accessing Cloudflare API" --result "DONE" --color GREEN
    display --indent 6 --text "- Checking if domain exists" --result "DONE" --color GREEN
    log_event "info" "Accessing Cloudflare API ..."
    log_event "info" "Getting Zone ID for domain: ${zone_name}"
    log_event "debug" "Running: curl -s -X GET \"https://api.cloudflare.com/client/v4/zones?name=${zone_name}\" -H \"X-Auth-Email: ${auth_email}\" -H \"X-Auth-Key: ${auth_key}\" -H \"Content-Type: application/json\" | grep -Po '(?<=\"id\":\")[^\"]*' | head -1"

    # Get Zone ID
    zone_id="$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zone_name}" \
        -H "X-Auth-Email: ${auth_email}" \
        -H "X-Auth-Key: ${auth_key}" \
        -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        log_event "info" "Zone ID found: ${zone_id} for domain ${zone_name}"
        display --indent 8 --text "Domain ${zone_name} found" --tcolor GREEN

        # Return
        echo "${zone_id}"

    else

        log_event "info" "Zone ID not found: ${zone_id} for domain ${zone_name}. Maybe domain is not configured yet."
        display --indent 8 --text "Domain ${zone_name} not found" --tcolor YELLOW

        return 1

    fi

}

function _cloudflare_clear_garbage_output() {

    # Remove Cloudflare API garbage output
    clear_last_line
    clear_last_line
    clear_last_line
    clear_last_line

}

################################################################################

function cloudflare_ask_root_domain() {

    # $1 = ${suggested_root_domain}

    local suggested_root_domain=$1
    local root_domain

    root_domain=$(whiptail --title "Root Domain" --inputbox "Insert the root domain of the Project (Only for Cloudflare API). Example: broobe.com" 10 60 "${suggested_root_domain}" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        # Return
        echo "${root_domain}"

    fi

}

function cloudflare_get_zone_info() {

    log_event "info" "Getting zone information for: ${zone_name}"

    zone_info="$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zone_name}&status=active" \
        -H "X-Auth-Email: ${auth_email}" \
        -H "X-Auth-Key: ${auth_key}" \
        -H "Content-Type: application/json")"

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        log_event "debug" "Zone information: ${zone_info}"

        # Return
        echo "${zone_id}"

    else

        return 1

    fi

}

function cloudflare_domain_exists() {

    # $1 = ${root_domain}

    local root_domain=$1

    local zone_name
    local zone_id

    zone_id="$(_cloudflare_get_zone_id "${root_domain}")"
    exitstatus=$?
    if [[ ${exitstatus} -eq 0 || ${zone_id} != "" ]]; then

        # Return
        return 0

    else

        # Return
        return 1
    fi

}

function cloudflare_clear_cache() {

    # $1 = ${root_domain}

    local root_domain=$1

    local zone_name
    local purge_cache

    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        # Log
        log_event "info" "Clearing Cloudflare cache for domain: ${root_domain}"
        log_event "debug" "Running: curl -s -X DELETE \"https://api.cloudflare.com/client/v4/zones/${zone_id}/purge_cache\" -H \"X-Auth-Email: ${auth_email}\" -H \"X-Auth-Key: ${auth_key}\" -H \"Content-Type:application/json\" --data '{\"purge_everything\":true}')"

        purge_cache="$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${zone_id}/purge_cache" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type:application/json" \
            --data '{"purge_everything":true}')"

        if [[ ${purge_cache} == *"\"success\":false"* || ${purge_cache} == "" ]]; then
            message="Error trying to clear Cloudflare cache. Results:\n${update}"
            log_event "error" "${message}"
            display --indent 6 --text "- Clearing Cloudflare cache" --result "FAIL" --color RED
            return 1

        else
            message="Cache cleared for domain: ${root_domain}"
            log_event "info" "${message}"
            display --indent 6 --text "- Clearing Cloudflare cache" --result "DONE" --color GREEN
        fi

    else

        return 1

    fi

}

function cloudflare_set_development_mode() {

    # $1 = ${root_domain}
    # $2 = ${dev_mode}

    local root_domain=$1
    local dev_mode=$2

    local purge_cache

    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        log_event "info" "Enabling Development Mode for domain: ${root_domain}"

        dev_mode_result="$(curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/settings/development_mode" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json" \
            --data "{\"value\":\"${dev_mode}\"}")"

        # Remove Cloudflare API garbage output
        _cloudflare_clear_garbage_output

        if [[ ${dev_mode_result} == *"\"success\":false"* || ${dev_mode_result} == "" ]]; then
            message="Error trying to change development mode for ${root_domain}. Results:\n ${dev_mode_result}"
            log_event "error" "${message}"
            display --indent 2 --text "- Enabling development mode" --result "FAIL" --color RED

            return 1

        else
            message="Development mode for ${root_domain} is ${dev_mode}"
            log_event "info" "${message}"
            display --indent 2 --text "- Enabling development mode" --result "DONE" --color GREEN

        fi

    else

        return 1

    fi

}

function cloudflare_get_ssl_mode() {

    # $1 = ${root_domain}

    local root_domain=$1

    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        log_event "info" "Gettinh SSL Mode for: ${zone_name}"
        display --indent 6 --text "- Gettinh SSL Mode for: ${zone_name}"

        ssl_mode_result=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/settings/ssl" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json")

        # Return
        # Possible return values: off, flexible, full, strict
        echo "${ssl_mode_result}"

    else

        return 1

    fi

}

function cloudflare_set_ssl_mode() {

    # $1 = ${root_domain}
    # $2 = ${ssl_mode} default value: off, valid values: off, flexible, full, strict

    local root_domain=$1
    local ssl_mode=$2

    local ssl_mode_result

    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then

        log_event "info" "Setting SSL Mode for: ${zone_name}"
        display --indent 6 --text "- Setting SSL Mode for: ${zone_name}"

        ssl_mode_result="$(curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/settings/ssl" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json" \
            --data "{\"value\":\"${ssl_mode}\"}")"

        # Remove Cloudflare API garbage output
        _cloudflare_clear_garbage_output

        if [[ ${ssl_mode_result} == *"\"success\":false"* || ${ssl_mode_result} == "" ]]; then
            message="Error trying to change ssl mode for ${root_domain}. Results:\n ${ssl_mode_result}"
            log_event "error" "${message}"
            return 1

        else
            message="SSL mode for ${root_domain} is ${ssl_mode}"
            log_event "info" "${message}"

        fi

    else

        return 1

    fi

}

function cloudflare_record_exists() {

    # $1 = ${root_domain}
    # $2 = ${domain}

    local root_domain=$1
    local domain=$2

    # Cloudflare API to change DNS records
    log_event "info" "Checking if record ${domain} exists"

    # Only for better readibility
    record_name="${domain}"

    # Retrieve zone_id
    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    # Retrieve record_id
    record_id="$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${record_name}" -H "X-Auth-Email: ${auth_email}" -H "X-Auth-Key: ${auth_key}" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*')"

    log_event "debug" "Last command executed: curl -s -X GET \"https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${record_name}\" -H \"X-Auth-Email: ${auth_email}\" -H \"X-Auth-Key: ${auth_key}\" -H \"Content-Type: application/json\" | grep -Po '(?<=\"id\":\")[^\"]*'"

    exitstatus=$?
    if [[ ${record_id} == "" ]]; then

        log_event "info" "Record ${record_name} not found on Cloudflare"
        display --indent 6 --text "- Record ${record_name} not found on Cloudflare" --result "FAIL" --color RED

        return 1

    else

        log_event "info" "Record ${record_name} found with id: ${record_id}"

        # Return
        echo "${record_id}"

    fi

}

function cloudflare_set_a_record() {

    # $1 = ${root_domain}
    # $2 = ${domain}
    # $3 = ${proxy_status} true/false

    local root_domain=$1
    local domain=$2
    local proxy_status=$3

    local ttl
    local record_type
    local cur_ip
    local zone_id
    local record_id

    record_name=${domain}

    #TODO: in the future we must rewrite the vars and remove this ugly replace
    record_type="A"
    ttl=1 #1 for Auto

    if [[ -z "${proxy_status}" || ${proxy_status} == "" || ${proxy_status} == "false" ]]; then

        # Default value
        proxy_status=false #need to be a bool, not a string

    else

        proxy_status=true #need to be a bool, not a string

    fi

    cur_ip="${SERVER_IP}"

    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    record_id=$(cloudflare_record_exists "${root_domain}" "${record_name}")

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 && ${record_id} != "" ]]; then

        # Log
        display --indent 6 --text "- Changing ${record_name} IP ..."
        log_event "debug" "Running: curl -s -X DELETE \"https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}\" -H \"X-Auth-Email: ${auth_email}\" -H \"X-Auth-Key: ${auth_key}\" -H \"Content-Type: application/json\""

        # First delete
        delete="$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json")"

        log_event "debug" "Running: curl -s -X POST \"https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records\" -H \"X-Auth-Email: ${auth_email}\" -H \"X-Auth-Key: ${auth_key}\" -H \"Content-Type: application/json\"--data \"{\"type\":\"${record_type}\",\"name\":\"${record_name}\",\"content\":\"${cur_ip}\",\"ttl\":${ttl},\"priority\":10,\"proxied\":${proxy_status}}\")"\"

        # Then create (work-around because sometimes update an entry does not work)
        update="$(curl -X POST "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"${record_type}\",\"name\":\"${record_name}\",\"content\":\"${cur_ip}\",\"ttl\":${ttl},\"priority\":10,\"proxied\":${proxy_status}}")"

        # Remove Cloudflare API garbage output
        _cloudflare_clear_garbage_output

        if [[ ${update} == *"\"success\":false"* || ${update} == "" ]]; then
            message="API UPDATE FAILED. RESULTS:\n${update}"
            log_event "error" "${message}"
            display --indent 6 --text "- Updating subdomain on Cloudflare" --result "FAIL" --color RED
            display --indent 8 --text "${message}" --tcolor RED

            return 1

        else
            message="IP changed to: ${SERVER_IP}"
            log_event "info" "${message}"
            display --indent 6 --text "- Updating subdomain on Cloudflare" --result "DONE" --color GREEN
            display --indent 8 --text "IP: ${SERVER_IP}" --tcolor GREEN

        fi

    else

        display --indent 6 --text "- Adding the subdomain: ${record_name}"
        log_event "debug" "RECORD_ID not found. Trying to add the subdomain: ${record_name}"

        update="$(curl -X POST "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"${record_type}\",\"name\":\"${record_name}\",\"content\":\"${cur_ip}\",\"ttl\":${ttl},\"priority\":10,\"proxied\":${proxy_status}}")"

        exitstatus=$?
        if [[ ${exitstatus} -eq 0 ]]; then

            # Remove Cloudflare API garbage output
            _cloudflare_clear_garbage_output

            display --indent 6 --text "- Creating subdomain ${record_name}" --result "DONE" --color GREEN
            log_event "info" "Subdomain ${record_name} added successfully"

        else

            # Remove Cloudflare API garbage output
            _cloudflare_clear_garbage_output

            display --indent 6 --text "- Creating subdomain ${record_name}" --result "FAIL" --color RED
            log_event "error" "Error creating subdomain ${record_name}"
            log_event "debug" "Last command executed: curl -X POST \"https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records\" -H \"X-Auth-Email: ${auth_email}\" -H \"X-Auth-Key: ${auth_key}\" -H \"Content-Type: application/json\" --data \"{\"type\":\"${record_type}\",\"name\":\"${record_name}\",\"content\":\"${cur_ip}\",\"ttl\":${ttl},\"priority\":10,\"proxied\":${proxy_status}}\""

        fi

    fi

}

function cloudflare_delete_a_record() {

    # $1 = ${root_domain}
    # $2 = ${domain}

    local root_domain=$1
    local domain=$2

    # Cloudflare API to delete record
    log_event "info" "Accessing to Cloudflare API to delete record ${domain}"

    record_name="${domain}"

    #TODO: in the future we must rewrite the vars and remove this ugly replace
    record_type="A"
    ttl=1 #1 for Auto

    cur_ip=${SERVER_IP}

    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    record_id=$(cloudflare_record_exists "${root_domain}" "${record_name}")

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 && ${record_id} != "" ]]; then # Record found on Cloudflare

        log_event "info" "Trying to delete the record ..."

        delete="$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json")"

        # Remove Cloudflare API garbage output
        _cloudflare_clear_garbage_output

        if [[ ${update} == *"\"success\":false"* || ${update} == "" ]]; then

            message="A record delete failed. Results:\n${delete}"
            log_event "error" "${message}"
            log_event "debug" "Last command executed: curl -s -X DELETE \"https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}\" -H \"X-Auth-Email: ${auth_email}\" -H \"X-Auth-Key: ${auth_key}\" -H \"Content-Type: application/json\""
            display --indent 6 --text "- Deleting A record from Cloudflare" --result "FAIL" --color RED
            display --indent 8 --text "${message}" --tcolor RED

            return 1

        else
            message="A record deleted: ${record_name}"
            log_event "info" "${message}"
            display --indent 6 --text "- Deleting A record from Cloudflare" --result "DONE" --color GREEN
            display --indent 8 --text "Record deleted: ${record_name}" --tcolor YELLOW

        fi

        return 0

    else

        # Record not found
        return 1

    fi

}

function cloudflare_set_cache_ttl_value() {

    # $1 = ${root_domain}
    # $2 = ${cache_ttl_value} - default value: 14400, valid values: 0, 30, 60, 300, 1200, 1800, 3600, 7200, 10800, 14400, 18000, 28800, 43200, 57600, 72000, 86400, 172800, 259200, 345600, 432000, 691200, 1382400, 2073600, 2678400, 5356800, 16070400, 31536000
    #                 notes: Setting a TTL of 0 is equivalent to selecting 'Respect Existing Headers'

    local root_domain=$1
    local cache_ttl_value=$2

    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then # Zone found

        cache_ttl_result="$(curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/settings/browser_cache_ttl" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json" \
            --data "{\"value\":\"${cache_ttl_value}\"}")"

        if [[ ${cache_ttl_result} == *"\"success\":false"* || ${cache_ttl_result} == "" ]]; then
            message="Error trying to set cache ttl for ${root_domain}. Results:\n ${cache_ttl_result}"
            log_event "error" "${message}"
            return 1

        else
            message="Cache TTL value for ${root_domain} is ${cache_ttl_result}"
            log_event "info" "${message}"

        fi

    else

        # Zone not found
        return 1

    fi
}

################################################################################

# PRO

function cloudflare_set_http3_setting() {

    # $1 = ${root_domain}
    # $2 = ${http3_setting} - default value: off, valid values: on, off

    local root_domain=$1
    local http3_setting=$2

    zone_id=$(_cloudflare_get_zone_id "${root_domain}")

    exitstatus=$?
    if [[ ${exitstatus} -eq 0 ]]; then # Zone found

        cache_ttl_result="$(curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${zone_id}/settings/http3" \
            -H "X-Auth-Email: ${auth_email}" \
            -H "X-Auth-Key: ${auth_key}" \
            -H "Content-Type: application/json" \
            --data "{\"value\":\"${http3_setting}\"}")"

        if [[ ${cache_ttl_result} == *"\"success\":false"* || ${cache_ttl_result} == "" ]]; then
            message="Error trying to set http3 for ${root_domain}. Results:\n ${cache_ttl_result}"
            log_event "error" "${message}"
            return 1

        else
            message="HTTP3 setting for ${root_domain} is ${cache_ttl_result}"
            log_event "info" "${message}"

        fi

    else

        # Zone not found
        return 1

    fi

}
