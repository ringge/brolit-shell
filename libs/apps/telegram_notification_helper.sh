#!/usr/bin/env bash
#
# Autor: BROOBE. web + mobile development - https://broobe.com
# Version: 3.0.25
################################################################################
#
# It uses globals defined on telegram.conf
#
# 	${botfather_key}
#	${telegram_user_id}
#

function telegram_send_notification() {

    # $1 = {notification_title}
    # $2 = {notification_content}
    # $3 = {notification_type}

	local notification_title=$1
	local notification_content=$2
	local notification_type=$3

	local timeout 
	local notif_sound 
	local notif_text 
	local notif_url 
	local display_mode

	# Display mode
	display_mode="HTML"
	
	# API timeout
	timeout="10"
	
	# API URL
	notif_url="https://api.telegram.org/bot${botfather_key}/sendMessage"
		
	# notif_sound = 1 for silent notification (without sound)
	notif_sound=0
	if [[ ${notification_type} -eq 1 ]] ; then
		notif_sound=1
	fi
	
	# Notification text
	notif_text="<b>${notification_title}: </b><pre>${notification_content}</pre>"
	
	# Log
	log_event "info" "Sending Telegram notification ..."

	# Telegram command
	telegram_notif_response="$(curl --silent --insecure --max-time "${timeout}" --data chat_id="${telegram_user_id}" --data "disable_notification=${notif_sound}" --data "parse_mode=${display_mode}" --data "text=${notif_text}" "${notif_url}")"
	
	# Check Result
	telegram_notif_result="$(echo "${telegram_notif_response}" | grep "ok" | cut -d ":" -f2 | cut -d "," -f1)"
	if [[ ${telegram_notif_result} == "true" ]]; then
		# Log on success
		log_event "info" "Telegram notification sent!"
		display --indent 6 --text "- Sending Telegram notification" --result "DONE" --color GREEN
	
	else
		# Log on failure
		log_event "error" "Telegram notification error!"
		log_event "debug" "Telegram api call: curl --silent --insecure --max-time ${timeout} --data chat_id=${telegram_user_id} --data disable_notification=${notif_sound} --data parse_mode=${display_mode} --data text=${notif_text} ${notif_url}"
		log_event "debug" "Telegram notification result: ${telegram_notif_result}"
		log_event "debug" "Telegram notification response: ${telegram_notif_response}"
		display --indent 6 --text "- Sending Telegram notification" --result "FAIL" --color RED

	fi

}