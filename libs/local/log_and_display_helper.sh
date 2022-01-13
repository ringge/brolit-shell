#!/usr/bin/env bash
#
# Author: BROOBE - A Software Development Agency - https://broobe.com
# Version: 3.2-alpha1
################################################################################
#
# Log and Display Helper: Log and display functions.
#
################################################################################

function _timestamp() {

  date +"%T"

}

################################################################################
# Private function to make spinner works
#
# Arguments:
#  $1 start/stop
#
#  on start: $2 display message
#  on stop : $2 process exit status
#            $3 spinner function pid (supplied from spinner_stop)
#
# Outputs:
#  nothing
################################################################################

function _spinner() {

  #local on_success="DONE"
  #local on_fail="FAIL"

  case $1 in

  start)

    # calculate the column where spinner and status msg will be displayed
    TEXT=$2
    INDENT=6
    LINESIZE=$(
      export LC_ALL=
      echo "${TEXT}" | wc -m | tr -d ' '
    )
    if [[ ${INDENT} -gt 0 ]]; then SPACES=$((62 - INDENT - LINESIZE)); fi
    if [[ ${SPACES} -lt 0 ]]; then SPACES=0; fi

    echo -e -n "\033[${INDENT}C${TEXT}${NORMAL}\033[${SPACES}C" >&2

    # start spinner
    i=1
    sp='\|/-'
    delay=${SPINNER_DELAY:-0.15}

    while :; do
      printf "\b${sp:i++%${#sp}:1}" >&2
      sleep "${delay}"
    done

    ;;

  stop)

    if [[ -z ${3} ]]; then
      # spinner is not running
      exit 1
    fi

    # Remove start spinner line
    echo "" >&2
    clear_previous_lines "1"

    kill "${3}" >/dev/null 2>&1

    ;;

  *)
    #invalid argument
    exit 1
    ;;

  esac

}

################################################################################
# Start spinner
#
# Arguments:
#   $1 = msg to display
#
# Outputs:
#   nothing
################################################################################

function spinner_start() {

  if [[ ${QUIET} == "true" || ${EXEC_TYPE} == "alias" ]]; then return 0; fi

  _spinner "start" "${1}" &

  # set global spinner pid
  _sp_pid=$!
  disown

}

################################################################################
# Stop spinner
#
# Arguments:
#  $1 = command exit status
#
# Outputs:
#  nothing
################################################################################

function spinner_stop() {

  if [[ ${QUIET} == "true" || ${EXEC_TYPE} == "alias" ]]; then return 0; fi

  _spinner "stop" "${1}" "${_sp_pid}"
  unset _sp_pid

}

################################################################################
# Write on log
#
# Arguments:
#  $1 = {log_type} (success, info, warning, error, critical)
#  $2 = {message}
#  $3 = {console_display} optional (true or false, default is false)
#
# Outputs:
#  nothing
################################################################################

function log_event() {

  local log_type=$1
  local message=$2
  local console_display=$3

  if [[ ${EXEC_TYPE} == "alias" ]]; then
    # if alias, do not log
    return 0
  fi

  case ${log_type} in

  success)
    echo "$(_timestamp) > SUCCESS: ${message}" >>"${LOG}"
    if [[ ${console_display} == "true" && ${QUIET} == "false" ]]; then
      echo -e "${B_GREEN} > ${message}${ENDCOLOR}" >&2
    fi
    ;;

  info)
    echo "$(_timestamp) > INFO: ${message}" >>"${LOG}"
    if [[ ${console_display} == "true" && ${QUIET} == "false" ]]; then
      echo -e "${B_CYAN} > ${message}${ENDCOLOR}" >&2
    fi
    ;;

  warning)
    echo "$(_timestamp) > WARNING: ${message}" >>"${LOG}"
    if [[ ${console_display} == "true" && ${QUIET} == "false" ]]; then
      echo -e "${YELLOW}${ITALIC} > ${message}${ENDCOLOR}" >&2
    fi
    ;;

  error)
    echo "$(_timestamp) > ERROR: ${message}" >>"${LOG}"
    if [[ ${console_display} == "true" && ${QUIET} == "false" ]]; then
      echo -e "${RED} > ${message}${ENDCOLOR}" >&2
    fi
    ;;

  critical)
    echo "$(_timestamp) > CRITICAL: ${message}" >>"${LOG}"
    if [[ ${console_display} == "true" && ${QUIET} == "false" ]]; then
      echo -e "${B_RED} > ${message}${ENDCOLOR}" >&2
    fi
    ;;

  debug)
    if [[ ${DEBUG} == "true" ]]; then

      echo "$(_timestamp) > DEBUG: ${message}" >>"${LOG}"
      if [[ ${console_display} == "true" && ${QUIET} == "false" ]]; then
        echo -e "${B_MAGENTA} > ${message}${ENDCOLOR}" >&2
      fi

    fi
    ;;

  *)
    echo "$(_timestamp) > ${message}" >>"${LOG}"
    if [[ ${console_display} == "true" && ${QUIET} == "false" ]]; then
      echo -e "${CYAN}${B_DEFAULT} > ${message}${ENDCOLOR}" >&2
    fi
    ;;

  esac

}

################################################################################
# Break line on log
#
# Arguments:
#  $1 = {console_display} optional (true or false, emtpy equals false)
#
# Outputs:
#   nothing
################################################################################

function log_break() {

  local console_display=$1

  local log_break

  if [[ ${EXEC_TYPE} == "alias" ]]; then
    # if alias, do not log
    return 0
  fi

  if [[ ${console_display} == "true" && ${QUIET} == "false" ]]; then

    log_break="        ----------------------------------------------------          "
    echo -e "${MAGENTA}${B_DEFAULT}${log_break}${ENDCOLOR}" >&2

  fi

  log_break="$(_timestamp) > ------------------------------------------------------------"
  echo "${log_break}" >>"${LOG}"

}

################################################################################
# Log section
#
# Arguments:
#  $1 = {message}
#
# Outputs:
#   nothing
################################################################################

function log_section() {

  local message=$1

  if [[ ${QUIET} == "false" && ${EXEC_TYPE} != "alias" ]]; then

    # Console Display
    echo "" >&2
    echo -e "[+] Performing Action: ${YELLOW}${B_DEFAULT}${message}${ENDCOLOR}" >&2
    #echo "--------------------------------------------------" >&2
    echo "—————————————————————————————————————————————————————————" >&2

    # Log file
    echo "$(_timestamp) > ------------------------------------------------------------" >>"${LOG}"
    echo "$(_timestamp) > [+] Performing Action: ${message}" >>"${LOG}"
    echo "$(_timestamp) > ------------------------------------------------------------" >>"${LOG}"

  fi

}

################################################################################
# Log sub-section
#
# Arguments:
#  $1 = {message}
#
# Outputs:
#   nothing
################################################################################

function log_subsection() {

  local message=$1

  if [[ ${QUIET} != "true" && ${EXEC_TYPE} != "alias" ]]; then

    # Console Display
    echo "" >&2
    echo -e "    [·] ${CYAN}${B_DEFAULT}${message}${ENDCOLOR}" >&2
    echo "    —————————————————————————————————————————————————————" >&2

    # Log file
    echo "$(_timestamp) > ------------------------------------------------------------" >>"${LOG}"
    echo "$(_timestamp) > [·] ${message}" >>"${LOG}"
    echo "$(_timestamp) > ------------------------------------------------------------" >>"${LOG}"

  fi

}

################################################################################
# Clear screen
#
# Arguments:
#   none
#
# Outputs:
#   nothing
################################################################################

function clear_screen() {

  if [[ ${QUIET} != "true" && ${EXEC_TYPE} != "alias" ]]; then

    echo -en "\ec" >&2

  fi

}

################################################################################
# Clear previous lines
#
# Arguments:
#   $1 = {lines}
#
# Outputs:
#   nothing
################################################################################

function clear_previous_lines() {

  local lines=$1

  if [[ ${QUIET} != "true" && ${EXEC_TYPE} != "alias" ]]; then

    #loop starting $lines going down to 0
    for ((i=lines; i>0; i--)); do

      #tput cuu1;tput el

      printf "\033[1A" >&2
      echo -e "${F_DEFAULT}                                                                               ${ENDCOLOR}" >&2
      echo -e "${F_DEFAULT}                                                                               ${ENDCOLOR}" >&2
      printf "\033[1A" >&2
      printf "\033[1A" >&2

    done

  fi

}

################################################################################
# Display message on terminal
#
# Arguments:
#   --text, --color, --indent, --result, --tcolor, --tstyle
#
# Outputs:
#   nothing
################################################################################

function display() {

  INDENT=0
  TEXT=""
  RESULT=""
  TCOLOR=""
  TSTYLE=""
  COLOR=""
  SPACES=0

  if [[ ${QUIET} == "true" || ${EXEC_TYPE} == "alias" ]]; then return 0; fi

  while [ $# -ge 1 ]; do

    case $1 in

    --color)
      shift
      case $1 in
      GREEN) COLOR=${GREEN} ;;
      RED) COLOR=${RED} ;;
      WHITE) COLOR=${WHITE} ;;
      YELLOW) COLOR=${YELLOW} ;;
      MAGENTA) COLOR=${MAGENTA} ;;
      esac
      ;;

    --indent)
      shift
      INDENT=$1
      ;;

    --result)
      shift
      RESULT=$1
      ;;

    --tcolor)
      shift
      case $1 in
      GREEN) TCOLOR=${GREEN} ;;
      RED) TCOLOR=${RED} ;;
      WHITE) TCOLOR=${WHITE} ;;
      YELLOW) TCOLOR=${YELLOW} ;;
      MAGENTA) TCOLOR=${MAGENTA} ;;
      esac
      ;;

    --tstyle)
      shift
      case $1 in
      NORMAL) TSTYLE=${NORMAL} ;;
      BOLD) TSTYLE=${BOLD} ;;
      ITALIC) TSTYLE=${ITALIC} ;;
      UNDERLINED) TSTYLE=${UNDERLINED} ;;
      INVERTED) TSTYLE=${INVERTED} ;;
      esac
      ;;

    --text)
      shift
      TEXT=$1
      ;;

    *)
      echo "INVALID OPTION (Display): $1" >&2
      #ExitFatal
      ;;

    esac

    # Go to next parameter
    shift

  done

  if [[ -z "${RESULT}" ]]; then
    RESULTPART=""
  else

    # EXEC_TYPE defined globally
    if [[ ${EXEC_TYPE} == "default" ]]; then
      RESULTPART=" [ ${COLOR}${B_DEFAULT}${RESULT}${NORMAL} ]"
    else
      RESULTPART=" [ ${RESULT} ]"
    fi

  fi

  if [[ -n "${TEXT}" ]]; then
    SHOW=0

    if [[ ${SHOW} -eq 0 ]]; then

      # Display:
      # - for full shells, count with -m instead of -c, to support language locale (older busybox does not have -m)
      # - wc needs LANG to deal with multi-bytes characters but LANG has been unset in include/consts
      TEXT_C="$(string_remove_color_chars "${TEXT}")"

      LINESIZE="$(
        export LC_ALL=
        echo "${TEXT_C}" | wc -m | tr -d ' '
      )"

      if [[ "${INDENT}" -gt 0 ]]; then SPACES=$((62 - INDENT - LINESIZE)); fi
      if [[ "${SPACES}" -lt 0 ]]; then SPACES=0; fi

      if [[ ${EXEC_TYPE} == "default" ]]; then

        echo -e "\033[${INDENT}C${TCOLOR}${TSTYLE}${TEXT}${NORMAL}\033[${SPACES}C${RESULTPART}${DEBUGTEXT}" >&2

      else

        return 0

      fi

    fi

  fi

}
