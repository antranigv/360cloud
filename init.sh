#!/bin/sh

STARTTIME=$(date +%s)
[ "${1}" == "" ] && CONFIG="360cloud.conf" || CONFIG="${1}"

echo -e "\e[44mUsing the config file: ${CONFIG}\e[0m"

. ${CONFIG}


echo -e "\e[34mSetting up network interfaces\e[0m"

sysrc cloned_interfaces="bridge0"

sysrc ifconfig_bridge0="inet ${lan} descr cloud360"

ENDTIME=$(date +%s)
TIMSPENT=$(expr ${ENDTIME} - ${STARTTIME})

echo -e "\e[42mInstallation done, it took \e[45m${TIMSPENT} seconds\e[0m"
