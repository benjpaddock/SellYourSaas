#!/usr/bin/env bash

export now=`date +%Y%m%d%H%M%S`

echo
#echo "####################################### ${0} ${1}"
#echo "${0} ${@}"
#echo "# user id --------> $(id -u)"
#echo "# now ------------> $now"
#echo "# PID ------------> ${$}"
#echo "# PWD ------------> $PWD" 
#echo "# arguments ------> ${@}"
#echo "# path to me -----> ${0}"
#echo "# parent path ----> ${0%/*}"
#echo "# my name --------> ${0##*/}"
#echo "# realname -------> $(realpath ${0})"
#echo "# realname name --> $(basename $(realpath ${0}))"
#echo "# realname dir ---> $(dirname $(realpath ${0}))"

export PID=${$}
export scriptdir=$(dirname $(realpath ${0}))


echo "***** $0 *****"

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

echo "Disable cron begin"
echo "Disable cron begin" >>/tmp/post_inst_script.log

/etc/init.d/cron stop 2>&1 >>/tmp/post_inst_script.log
echo result = $? >>/tmp/post_inst_script.log

systemctl stop cron 2>&1 >>/tmp/post_inst_script.log
systemctl disable cron 2>&1 >>/tmp/post_inst_script.log

echo "Disable cron end"
echo "Disable cron end" >>/tmp/post_inst_script.log

exit 0
