#!/bin/bash
# Autor: broobe. web + mobile development - https://broobe.com
# Version: 2.9.9
################################################################################

source /root/.broobe-utils-options

################################################################################

send_mail_notification() {

    # $1- ${EMAIL_SUBJECT}
    # $2- ${EMAIL_CONTENT}

    local EMAIL_SUBJECT=$1
    local EMAIL_CONTENT=$2

    sendEmail -f ${SMTP_U} -t "${MAILA}" -u "${EMAIL_SUBJECT}" -o message-content-type=html -m "${EMAIL_CONTENT}" -s ${SMTP_SERVER}:${SMTP_PORT} -o tls=${SMTP_TLS} -xu ${SMTP_U} -xp ${SMTP_P}

}

mail_subject_status() {

    # $1 = ${STATUS_D}
    # $2 = ${STATUS_F}
    # $3 = ${OUTDATED}

    local STATUS_D=$1
    local STATUS_F=$2
    local OUTDATED=$3

    if [ "${STATUS_D}" = "ERROR" ] || [ "${STATUS_F}" = "ERROR" ]; then
        STATUS="⛔ ERROR"
        #STATUS_ICON="⛔"
    else
        if [ "${OUTDATED}" = true ]; then
            STATUS="⚠ WARNING"
            #STATUS_ICON="⚠"
        else
            STATUS="✅ OK"
            #STATUS_ICON="✅"
        fi
    fi

    echo $STATUS

}

remove_mail_notifications_files() {

    echo "  Removing temp files ..." >>$LOG
    echo -e ${YELLOW}" > Removing temp files ..."${ENDCOLOR}

    # TODO: no siempre se crean estos archivos, entonces suele tirar un error, mejorar
    rm ${PKG_MAIL} ${DB_MAIL} ${FILE_MAIL}

}

mail_server_status_section() {

    # $1 - ${IP}
    # $2 - ${DISK_U}

    local IP=$1
    local DISK_U=$2

    # extract % to compare
    local DISK_U_NS=$(echo ${DISK_U} | cut -f1 -d'%')

    if [ "$DISK_U_NS" -gt "45" ]; then
        SRV_COLOR='#fb2f2f'
        SRV_STATUS='WARNING'
        SRV_STATUS_ICON="⚠"
    else
        SRV_COLOR='#1DC6DF'
        SRV_STATUS='OK'
        SRV_STATUS_ICON="✅"
    fi

    SRV_HEADEROPEN_1='<div style="float:left;width:100%"><div style="font-size:14px;font-weight:bold;color:#FFF;float:left;font-family:Verdana,Helvetica,Arial;line-height:36px;background:'
    SRV_HEADEROPEN_2=${SRV_COLOR}
    SRV_HEADEROPEN_3=';padding:5px 0 10px 10px;width:100%;height:30px">'
    SRV_HEADERTEXT="Server Status: ${SRV_STATUS} ${SRV_STATUS_ICON}"
    SRV_HEADERCLOSE='</div>'
    SRV_HEADER=${SRV_HEADEROPEN_1}${SRV_HEADEROPEN_2}${SRV_HEADEROPEN_3}${SRV_HEADERTEXT}${SRV_HEADERCLOSE}

    SRV_BODYOPEN='<div style="color:#000;font-size:12px;line-height:32px;float:left;font-family:Verdana,Helvetica,Arial;background:#D8D8D8;padding:10px;width:100%;">'
    SRV_CONTENT="<b>Server IP: ${IP}</b><br /><b>Disk usage: ${DISK_U}</b><br />"
    SRV_BODYCLOSE='</div></div>'
    SRV_BODY=${SRV_BODYOPEN}${SRV_CONTENT}${SRV_BODYCLOSE}

    BODY_SRV=${SRV_HEADER}${SRV_BODY}

    echo ${BODY_SRV}
}

mail_package_status_section() {

    # $1 - ${OUTDATED}

    local OUTDATED=$1

    if [ "${OUTDATED}" = true ]; then
        PKG_COLOR='red'
        PKG_STATUS='OUTDATED'
    else
        PKG_COLOR='#1DC6DF'
        PKG_STATUS='OK'
    fi

    PKG_HEADEROPEN1='<div style="float:left;width:100%"><div style="font-size:14px;font-weight:bold;color:#FFF;float:left;font-family:Verdana,Helvetica,Arial;line-height:36px;background:'
    PKG_HEADEROPEN2=';padding:5px 0 10px 10px;width:100%;height:30px">'
    PKG_HEADEROPEN=${PKG_HEADEROPEN1}${PKG_COLOR}${PKG_HEADEROPEN2}
    PKG_HEADERTEXT="Packages Status: ${PKG_STATUS}"
    PKG_HEADERCLOSE='</div>'

    PKG_BODYOPEN=$(mail_section_start)
    PKG_BODYOPEN=$(mail_section_end)

    PKG_HEADER=$PKG_HEADEROPEN$PKG_HEADERTEXT$PKG_HEADERCLOSE

    PKG_MAIL="${BAKWP}/pkg-${NOW}.mail"
    PKG_MAIL_VAR=$(<${PKG_MAIL})

    BODY_PKG=${PKG_HEADER}${PKG_BODYOPEN}${PKG_MAIL_VAR}${PKG_BODYCLOSE}

    echo ${BODY_PKG}
}

mail_package_section() {

    # $1 - ${PACKAGES}

    local PACKAGES=$1

    OUTDATED=false
    echo "" >${BAKWP}/pkg-${NOW}.mail
    for pk in ${PACKAGES[@]}; do
        PK_VI=$(apt-cache policy ${pk} | grep Installed | cut -d ':' -f 2)
        PK_VC=$(apt-cache policy ${pk} | grep Candidate | cut -d ':' -f 2)
        if [ ${PK_VI} != ${PK_VC} ]; then
            OUTDATED=true
            echo " > ${pk} ${PK_VI} -> ${PK_VC} <br />" >>${BAKWP}/pkg-${NOW}.mail
        fi
    done

}

mail_filesbackup_section() {

    # $1 - ${ERROR}
    # $2 - ${ERROR_TYPE}
    # $3 - ${BACKUPED_LIST}
    # $4 - ${BK_FL_SIZES}

    local ERROR=$1
    local ERROR_TYPE=$2
    local BACKUPED_LIST=$3
    local BK_FL_SIZES=$4

    local BK_TYPE="Files"

    if [ "$ERROR" = true ]; then
        STATUS_ICON_F="💩"
        STATUS_F="ERROR"
        CONTENT="<b>$BK_TYPE Backup Error: $ERROR_TYPE<br />Please check log file.</b> <br />"
        COLOR='red'
        #echo " > File Backup ERROR: $ERROR_TYPE" >>$LOG
    else
        STATUS_ICON_F="✅"
        STATUS_F="OK"
        CONTENT=""
        COLOR='#1DC6DF'
        SIZE_LABEL=""
        FILES_LABEL='<b>Backup files includes:</b><br /><div style="color:#000;font-size:12px;line-height:24px;padding-left:10px;">'
        FILES_INC=""
        COUNT=0
        for t in "${BACKUPED_LIST[@]}"; do
            BK_FL_SIZE=${BK_FL_SIZES[$COUNT]}
            FILES_INC="$FILES_INC $t ${BK_FL_SIZE}<br />"
            COUNT=$((COUNT + 1))
        done

        FILES_LABEL_END='</div>'
        #echo " > File Backup OK" >>$LOG
        #echo -e ${GREEN}" > File Backup OK"${ENDCOLOR}

        if [ "${DUP_BK}" = true ]; then
            DBK_SIZE=$(du -hs $DUP_ROOT | cut -f1)
            DBK_SIZE_LABEL="Duplicity Backup size: <b>$DBK_SIZE</b><br /><b>Duplicity Backup includes:</b><br />$DUP_FOLDERS"
        fi

    fi

    HEADEROPEN1='<div style="float:left;width:100%"><div style="font-size:14px;font-weight:bold;color:#FFF;float:left;font-family:Verdana,Helvetica,Arial;line-height:36px;background:'
    HEADEROPEN2=';padding:5px 0 10px 10px;width:100%;height:30px">'
    HEADEROPEN=$HEADEROPEN1$COLOR$HEADEROPEN2
    HEADERTEXT="Files Backup: ${STATUS_F} ${STATUS_ICON_F}"
    HEADERCLOSE='</div>'

    BODYOPEN='<div style="color:#000;font-size:12px;line-height:32px;float:left;font-family:Verdana,Helvetica,Arial;background:#D8D8D8;padding:10px;width:100%;">'
    BODYCLOSE='</div></div>'

    MAIL_FOOTER=$(mail_footer "${SCRIPT_V}")

    HEADER=$HEADEROPEN$HEADERTEXT$HEADERCLOSE
    BODY=$BODYOPEN$CONTENT$SIZE_LABEL$FILES_LABEL$FILES_INC$FILES_LABEL_END$DBK_SIZE_LABEL$BODYCLOSE
    FOOTER=$FOOTEROPEN$SCRIPTSTRING$FOOTERCLOSE

    echo $HEADER >${BAKWP}/file-bk-${NOW}.mail
    echo $BODY >>${BAKWP}/file-bk-${NOW}.mail
    echo $FOOTER >>${BAKWP}/file-bk-${NOW}.mail

}

mail_mysqlbackup_section() {

    # $1 - ${ERROR}
    # $2 - ${ERROR_TYPE}
    # $3 - ${BACKUPEDLIST}
    # $4 - ${BK_DB_SIZES}

    local ERROR=$1
    local ERROR_TYPE=$2
    local BACKUPEDLIST=$3
    local BK_DB_SIZES=$4

    BK_TYPE="Database"

    if [ "${ERROR}" = true ]; then
        STATUS_ICON_D="💩"
        STATUS_D="ERROR"
        CONTENT_D="<b>${BK_TYPE} Backup with errors:<br />${ERROR_TYPE}<br /><br />Please check log file.</b> <br />"
        COLOR_D='red'
        #echo " > Backup with errors: $2." >>$LOG

    else
        STATUS_ICON_D="✅"
        STATUS_D="OK"
        CONTENT_D=""
        COLOR_D='#1DC6DF'
        SIZE_D=""
        FILES_LABEL_D='<b>Backup files includes:</b><br /><div style="color:#000;font-size:12px;line-height:24px;padding-left:10px;">'
        FILES_INC_D=""

        COUNT=0
        for t in "${BACKUPEDLIST[@]}"; do
            BK_DB_SIZE=${BK_DB_SIZES[$COUNT]}
            FILES_INC_D="$FILES_INC_D $t ${BK_DB_SIZE}<br />"
            COUNT=$((COUNT + 1))
        done

        FILES_LABEL_D_END='</div>'
        #echo " > Database Backup OK" >>$LOG
        #echo -e ${GREEN}" > Database Backup OK"${ENDCOLOR}

    fi

    HEADEROPEN1_D='<div style="float:left;width:100%"><div style="font-size:14px;font-weight:bold;color:#FFF;float:left;font-family:Verdana,Helvetica,Arial;line-height:36px;background:'
    HEADEROPEN2_D=';padding:5px 0 10px 10px;width:100%;height:30px">'
    HEADEROPEN_D=${HEADEROPEN1_D}${COLOR_D}${HEADEROPEN2_D}
    HEADERTEXT_D="Database Backup: ${STATUS_D} ${STATUS_ICON_D}"
    HEADERCLOSE_D='</div>'

    BODYOPEN_D='<div style="color:#000;font-size:12px;line-height:32px;float:left;font-family:Verdana,Helvetica,Arial;background:#D8D8D8;padding:10px 0 0 10px;width:100%;">'
    BODYCLOSE_D='</div>'

    HEADER_D=${HEADEROPEN_D}${HEADERTEXT_D}${HEADERCLOSE_D}
    BODY_D=$BODYOPEN_D$CONTENT_D$SIZE_D$FILES_LABEL_D$FILES_INC_D$FILES_LABEL_D_END$BODYCLOSE_D

    echo $HEADER_D >${BAKWP}/db-bk-${NOW}.mail
    echo $BODY_D >>${BAKWP}/db-bk-${NOW}.mail

}

mail_section_start() {

    BODYOPEN='<div style="color:#000;font-size:12px;line-height:32px;float:left;font-family:Verdana,Helvetica,Arial;background:#D8D8D8;padding:10px 0 0 10px;width:100%;">'

    echo ${BODYOPEN}
}

mail_section_end() {

    BODYCLOSE='</div>'

    echo ${BODYCLOSE}

}

mail_footer() {

    # $1 = ${SCRIPT_V}

    local SCRIPT_V=$1

    FOOTEROPEN='<div style="font-size:10px;float:left;font-family:Verdana,Helvetica,Arial;text-align:right;padding-right:5px;width:100%;height:20px">'
    SCRIPTSTRING="Script Version: ${SCRIPT_V} by Broobe."
    FOOTERCLOSE='</div></div>'

    HTMLCLOSE=$(mail_html_end)

    MAIL_FOOTER=${FOOTEROPEN}${SCRIPTSTRING}${FOOTERCLOSE}${HTMLCLOSE}

    echo ${MAIL_FOOTER}
}

mail_html_start() {

    HTMLOPEN='<html><body>'

    echo ${HTMLOPEN}
}

mail_html_end() {

    HTMLCLOSE='</body></html>'

    echo ${HTMLCLOSE}
}
