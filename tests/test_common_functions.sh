#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha4
#############################################################################

function test_common_funtions() {

    #test_get_root_domain
    #test_get_subdomain_part
    #test_extract_domain_extension
    #test_jsonify_function_return
    test_json_write_function

}

function test_get_root_domain() {

    local result

    log_subsection "Test: get_root_domain"

    result="$(get_root_domain "www.broobe.com")"
    if [[ ${result} = "broobe.com" ]]; then
        display --indent 6 --text "- get_root_domain result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_root_domain with www.broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_root_domain "dev.broobe.com")"
    if [[ ${result} = "broobe.com" ]]; then
        display --indent 6 --text "- get_root_domain result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_root_domain with www.broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_root_domain "dev.www.broobe.com")"
    if [[ ${result} = "broobe.com" ]]; then
        display --indent 6 --text "- get_root_domain result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_root_domain with dev.www.broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_root_domain "broobe.hosting")"
    if [[ ${result} = "broobe.hosting" ]]; then
        display --indent 6 --text "- get_root_domain result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_root_domain with broobe.hosting" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_root_domain "www.broobe.hosting")"
    if [[ ${result} = "broobe.hosting" ]]; then
        display --indent 6 --text "- get_root_domain result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_root_domain with www.broobe.hosting" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_root_domain "www.dev.broobe.hosting")"
    if [[ ${result} = "broobe.hosting" ]]; then
        display --indent 6 --text "- get_root_domain result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_root_domain with www.dev.broobe.hosting" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

}

function test_get_subdomain_part() {

    local result

    log_subsection "Test: get_subdomain_part"

    result="$(get_subdomain_part "www.broobe.com")"
    if [[ ${result} = "www" ]]; then
        display --indent 6 --text "- get_subdomain_part result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_subdomain_part with www.broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_subdomain_part "broobe.com")"
    if [[ ${result} = "" ]]; then
        display --indent 6 --text "- get_subdomain_part result 'empty_response'" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_subdomain_part with broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_subdomain_part "test.broobe.com")"
    if [[ ${result} = "test" ]]; then
        display --indent 6 --text "- get_subdomain_part result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_subdomain_part with test.broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_subdomain_part "test.01.broobe.com")"
    if [[ ${result} = "test.01" ]]; then
        display --indent 6 --text "- get_subdomain_part result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_subdomain_part with test.01.broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(get_subdomain_part "dev.prueba.broobe.hosting")"
    if [[ ${result} = "dev.prueba" ]]; then
        display --indent 6 --text "- get_subdomain_part result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- get_subdomain_part with dev.prueba.broobe.hosting" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

}

function test_extract_domain_extension() {

    local result

    log_subsection "Testing Domain Functions"

    result="$(extract_domain_extension "broobe.com")"
    if [[ ${result} = "broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "broobe.com.ar")"
    if [[ ${result} = "broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with broobe.com.ar" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "broobe.ar")"
    if [[ ${result} = "broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with broobe.ar" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "test.broobe.com.ar")"
    if [[ ${result} = "test.broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with test.broobe.com.ar" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "old.test.broobe.com.ar")"
    if [[ ${result} = "old.test.broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with old.test.broobe.com.ar" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "old.test.broobe.ar")"
    if [[ ${result} = "old.test.broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with old.test.broobe.ar" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "old.dev.test.broobe.com")"
    if [[ ${result} = "old.dev.test.broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with old.dev.test.broobe.com" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "old.dev.test.broobe")"
    if [[ ${result} = "" ]]; then
        display --indent 6 --text "- extract_domain_extension result 'empty response'" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with old.dev.test.broobe" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "old.dev.test.broobe.hosting")"
    if [[ ${result} = "old.dev.test.broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with old.dev.test.broobe.hosting" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

    result="$(extract_domain_extension "old.dev.test.broobe.com.ar")"
    if [[ ${result} = "old.dev.test.broobe" ]]; then
        display --indent 6 --text "- extract_domain_extension result ${result}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- extract_domain_extension with old.dev.test.broobe.com.ar" --result "FAIL" --color RED
        display --indent 6 --text "result: ${result}" --tcolor RED
    fi

}

function test_jsonify_function_return() {

    local config_file
    local config_field
    local server_roles

    log_subsection "jsonify_function_return"

    databases="$(mysql_list_databases "all")"

    jsonify_output "value-list" "${databases}"

    string_to_test="function_example_name function_example_return"

    jsonify_output "key-value" "${string_to_test}"

}

function test_json_write_function() {

    local config_file
    local config_field
    local server_roles

    log_subsection "json_write_function"

    config_file="assets/brolit_shell.conf"

    config_field="SERVER_ROLES.config[].webserver"

    server_roles="true"

    # Write json
    json_write_field "${config_file}" "${config_field}" "${server_roles}"

    # Read json
    config_value="$(json_read_field "${config_file}" "${config_field}")"

    if [[ ${config_value} == "true" ]]; then
        display --indent 6 --text "- result: ${config_value}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- result: ${config_value}" --result "FAIL" --color RED
    fi

}
