#!/bin/bash
#--------------------------------------------------------#

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi


echo "Search to know if we are a master server in /etc/sellyoursaas.conf"
masterserver=`grep 'masterserver=' /etc/sellyoursaas.conf | cut -d '=' -f 2`

cd /home


#echo "Remplacement user apache par www-data"
#find . -user apache -exec chown www-data {} \;

#echo "Remplacement group apache par www-data"
#find . -group apache -exec chgrp www-data {} \;

# Owner root
echo "Set owner and permission on logs directory"
chown root.adm /home/admin/logs/

echo "Set owner and permission on /home/admin/wwwroot/dolibarr_documents/ (except sellyoursaas)"
chmod g+ws /home/admin/wwwroot/dolibarr_documents/
chown admin.www-data /home/admin/wwwroot/dolibarr_documents
for fic in `ls /home/admin/wwwroot/dolibarr_documents | grep -v sellyoursaas`; 
do 
	chown -R admin.www-data $fic
done

if [[ "x$masterserver" == "x1" ]]; then
	echo We are on a master server, Set owner and permission on /home/admin/wwwroot/dolibarr_documents/sellyoursaas
	chown -R admin.www-data /home/admin/wwwroot/dolibarr_documents/sellyoursaas
fi
chmod -R ug+w /home/admin/wwwroot/dolibarr_documents

echo "Set owner and permission on /home/admin/wwwroot/dolibarr"
chown -R admin.admin /home/admin/wwwroot/dolibarr
chmod -R a-w /home/admin/wwwroot/dolibarr
chmod -R u+w /home/admin/wwwroot/dolibarr/.git

echo "Set owner and permission on /home/admin/wwwroot/dolibarr_nltechno"
chmod -R a-w /home/admin/wwwroot/dolibarr_nltechno 2>/dev/null
chmod -R u+w /home/admin/wwwroot/dolibarr_nltechno/.git 2>/dev/null

echo We are on a master server, Set owner and permission on /home/admin/wwwroot/dolibarr_sellyoursaas
chmod -R a-w /home/admin/wwwroot/dolibarr_sellyoursaas
chmod -R u+w /home/admin/wwwroot/dolibarr_sellyoursaas/.git

echo Set owner and permission on /home/admin/wwwroot/dolibarr/htdocs/conf/conf.php
chown www-data.admin /home/admin/wwwroot/dolibarr/htdocs/conf/conf.php
chmod o-rwx /home/admin/wwwroot/dolibarr/htdocs/conf/conf.php

echo "Nettoyage fichier logs error"
for fic in `ls -art /home/jail/home/osu*/dbn*/*_error.log`; do > $fic; done
echo "Nettoyage fichier logs dolibarr"
for fic in `ls -art /home/jail/home/osu*/dbn*/documents/dolibarr*.log`; do > $fic; done

echo "Nettoyage vieux fichiers tmp"
find /home/admin/wwwroot/dolibarr_documents/sellyoursaas/temp -maxdepth 1 -name "*.tmp" -type f -mtime +10 -exec rm {} \;

echo "Nettoyage vieux fichiers log"
find /home/admin/wwwroot/dolibarr_documents -maxdepth 1 -name "dolibarr*.log*" -type f -mtime +10 -exec rm {} \;
