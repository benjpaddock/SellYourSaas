#!/bin/bash
#-------------------------------------------
# A manual hook for letsencrypt renewal with DNS
#-------------------------------------------

verbose=true
echo ----- letsencrypt_authenticator.sh -----
echo "CERTBOT_DOMAIN=$CERTBOT_DOMAIN"
echo "CERTBOT_ALL_DOMAINS=$CERTBOT_ALL_DOMAINS"
echo "CERTBOT_VALIDATION=$CERTBOT_VALIDATION"
echo "CERTBOT_REMAINING_CHALLENGES=$CERTBOT_REMAINING_CHALLENGES"
export subdomain=$CERTBOT_DOMAIN
if [[ "x$subdomain" == "x" ]]; then
	export subdomain=`grep '^subdomain=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
fi
# Sanitize variable
subdomain=${subdomain//[^a-zA-Z0-9.-]/}


zone_file="/etc/bind/${subdomain}.hosts"
echo "zone_file=$zone_file"

#current_certificates="/etc/letsencrypt/live/withX.mydomain.com/*pem"

#LET'S ENCRYPT VARIABLES
#
#CERTBOT_DOMAIN: The domain being authenticated
#CERTBOT_ALL_DOMAINS: A comma-separated list of all domains challenged for the current certificate
#CERTBOT_VALIDATION: The validation string
#CERTBOT_TOKEN: Resource name part of the HTTP-01 challenge (HTTP-01 only)
#CERTBOT_REMAINING_CHALLENGES: Number of challenges remaining after the current challenge

if [ -z "$CERTBOT_DOMAIN" ] || [ -z "$CERTBOT_VALIDATION" ]
then
	echo "EMPTY DOMAIN OR VALIDATION : LET'S ENCRYPT ENV VARIABLES NOT SET"
	exit 2
fi

if [ ! -f "$zone_file" ] || [ ! -w "$zone_file" ]
then
	echo "ZONE FILE DOESN'T EXIST OR ISN'T WRITABLE: $zone_file"
	exit 3
fi


#current_checksums=$(md5sum $current_certificates)
#$verbose && echo -e "current certificates md5sums :\n$current_checksums"

old_serial=$(grep serial $zone_file |awk '{print $1}')
new_serial=$((old_serial+1))
old_challenge=$(grep _acme-challenge $zone_file | awk '{print $4}' | head -n 1)
new_challenge="\"$CERTBOT_VALIDATION\""
$verbose && echo "old serial : $old_serial"
$verbose && echo "new serial : $new_serial"
$verbose && echo "old challenge : $old_challenge"
$verbose && echo "new challenge : $new_challenge"

if [ "x$CERTBOT_REMAINING_CHALLENGES" == "x1" ]
then
	cp -f $zone_file $zone_file.auto.bck3
	awk '{ if ($0 ~ /^_acme-challenge\s+IN\s+TXT/) { if ($0 ~ /'$old_challenge'/) { print; print "_acme-challenge IN TXT \"'$CERTBOT_VALIDATION'\""; next} else {next} } {print} }' $zone_file.auto.bck3 > $zone_file;
	sed -i.auto.bck4 -e "s/$old_serial/$new_serial/" $zone_file

	systemctl restart bind9
	sleep 10
else
	sed -i.auto.bck -e "s/$old_challenge/$new_challenge/" $zone_file
	sed -i.auto.bck2 -e "s/$old_serial/$new_serial/" $zone_file

	systemctl restart bind9
	sleep 15
fi
