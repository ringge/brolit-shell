#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha2
#############################################################################

function test_php_helper_funtions() {

    test_php_set_version_on_config
    test_php_opcode_config

}

function test_php_set_version_on_config() {

    local current_phpv

    log_subsection "Test: php_set_version_on_config"

    # test file
    cp "${SFOLDER}/config/nginx/sites-available/wordpress_single" "/etc/nginx/sites-available/domain.com.conf"

    php_set_version_on_config "7.4" "/etc/nginx/sites-available/domain.com.conf"

    current_phpv=$(nginx_server_get_current_phpv "/etc/nginx/sites-available/domain.com.conf")
    if [[ ${current_phpv} = "7.4" ]]; then
        display --indent 6 --text "- php_set_version_on_config result ${current_phpv}" --result "PASS" --color WHITE
    else
        display --indent 6 --text "- php_set_version_on_config" --result "FAIL" --color RED
        display --indent 6 --text "current_phpv: ${current_phpv}" --tcolor RED
    fi

    # Clean
    rm "/etc/nginx/sites-available/domain.com.conf"

}

function test_php_opcode_config() {

    log_subsection "Test: php_opcode_config"

    cp "/etc/php/7.4/fpm/php.ini" "${SFOLDER}/tmp/php_op1.ini"
    php_opcode_config "enable" "${SFOLDER}/tmp/php_op1.ini"

    cp "${SFOLDER}/tmp/php_op1.ini" "${SFOLDER}/tmp/php_op2.ini"
    php_opcode_config "disable" "${SFOLDER}/tmp/php_op2.ini"

}
