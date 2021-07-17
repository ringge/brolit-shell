#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.0.45
################################################################################
#
# Json Helper: Functions to read and write json files.
#
################################################################################

################################################################################
# Read json field from file
#
# Arguments:
#   $1= ${json_file}
#   $2= ${json_field}
#
# Outputs:
#   ${json_field_value}
################################################################################

function json_read_field() {

    local json_file=$1
    local json_field=$2

    local json_field_value

    json_field_value="$(cat ${json_file} | jq -r ".${json_field}")"

    # Return
    echo "${json_field_value}"

}

################################################################################
# Write json field value
#
# Arguments:
#   $1= ${json_file}
#   $2= ${json_field}
#   $3= ${json_field_value}
#
# Outputs:
#   ${json_field_value}
################################################################################

function json_write_field() {

    local json_file=$1
    local json_field=$2
    local json_field_value=$3

    json_field_value="$(jq ".${json_field} = \"${json_field}\"" "${json_file}")" && echo "${json_field_value}" >"${json_file}"

    exitstatus=$?
    if [[ "${exitstatus}" -eq 0 ]]; then

        # Return
        echo "${json_field_value}"

    else

        log_event "error" "Getting value from ${json_field}" "false"
        return 1

    fi

}

function jsonify_output() {

    local mode=$1

    # Mode "key-value" example:
    # > echo "key1 value1 key2 value2" | ./key_value_pipe_to_json.sh
    # {'key1': value1, 'key2': value2}

    # Mode "value-list" example:
    # > echo "value1 value2 value3 value4" | ./value_pipe_to_json.sh
    # [ "value1" "value2" "value3" "value4" ]

    # Remove fir parameter
    shift

    if [[ ${mode} == "key-value" ]]; then

        arr=()

        while read x y; do
            arr=("${arr[@]}" $x $y)
        done

        vars=(${arr[@]})
        len=${#arr[@]}

        printf "{"
        for ((i = 0; i < len; i += 2)); do
            printf "\"${vars[i]}\": ${vars[i + 1]}"
            if [ $i -lt $((len - 2)) ]; then
                printf ", "
            fi
        done
        printf "}"
        echo

    else

        arr=()

        while read x y; do
            arr=("${arr[@]}" $x $y)
        done

        vars=(${arr[@]})
        len=${#arr[@]}

        printf "["
        for ((i = 0; i < len; i += 1)); do
            printf "\"${vars[i]}\""
            if [ $i -lt $((len - 1)) ]; then
                printf ", "
            fi
        done
        printf "]"
        echo

    fi

}
