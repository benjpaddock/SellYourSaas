#!/bin/bash
# Catch/Pull all backup of backups on local computer
#
# Put the following entry into your root cron
# /home/admin/wwwroot/dolibarr_sellyoursaas/scripts/backup_backup_backups.sh test|confirm /mnt/diskbackup remotebackupserver1,remotebackupserver2,...

#set -e

#source /etc/lsb-release

export now=`date +'%Y-%m-%d %H:%M:%S'`



echo "**** ${0} started"

if [ "x$1" == "x" ]; then
	echo "Usage:   ${0}  remotelogin  (test|confirm)"
	echo "Example: ${0}  admin        test"
	echo "Note:    The user running the script must have its public key declared on the backup server to backup"
	exit
fi

echo `date +'%Y-%m-%d %H:%M:%S'`" Start to copy backups of backup on local server"

export PID=${$}
export realpath=$(realpath "${0}")
export scriptdir=$(dirname "$realpath")
export script=${0##*/}

echo
echo "${0} ${@}"
echo "# user id --------> $(id -u)"
echo "# now ------------> $now"
echo "# PID ------------> ${$}"
echo "# PWD ------------> $PWD" 
echo "# arguments ------> ${@}"
echo "# path to me -----> ${0}"
echo "# parent path ----> ${0%/*}"
echo "# my name --------> ${0##*/}"
echo "# scriptdir-------> $scriptdir"

export backupdir=`grep '^backupdir=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
export remotebackupdir=`grep '^remotebackupdir=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
export remotebackupserver=`grep '^remotebackupserver=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
export remotebackupserverport=`grep '^remotebackupserverport=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
export EMAILFROM=`grep '^emailfrom=' /etc/sellyoursaas.conf | cut -d '=' -f 2`
export EMAILTO=`grep '^emailsupervision=' /etc/sellyoursaas.conf | cut -d '=' -f 2`

export testorconfirm=$2
export USER=$1

#export OPTIONS="-v -4 --stats -a --chmod=u=rwX --delete";
#export OPTIONS="-v -4 --stats -a --chmod=u=rwX --delete --delete-excluded";
export OPTIONS=" -4 --stats -rlt --chmod=u=rwX";

#export DISTRIB_RELEASE=`lsb_release -r -s`
#if [ "x$DISTRIB_RELEASE" == "x20.10" ]; then
#	# Version must be 20.10+ on both side !
#	#export OPTIONS="$OPTIONS --open-noatime" 
#	export OPTIONS="$OPTIONS"
#else 
#	export OPTIONS="$OPTIONS --noatime"
#fi

if [ "x$testorconfirm" != "xconfirm" ]; then
	export OPTIONS="-n $OPTIONS"
fi
if [ "x$USER" == "x" ]; then
	export USER="admin"
fi
if [ "x$3" == "x--delete" ]; then
	export OPTIONS="$OPTIONS --delete"
fi

if [ "x$remotebackupdir" == "x" ]; then
	export remotebackupdir=/mnt/diskbackup
fi
if [ "x$backupdir" == "x" ]; then
	export backupdir=/mnt/diskbackup/backup
fi
if [ "x$remotebackupserverport" == "x" ]; then
	export remotebackupserverport="22"
fi
echo "remotebackupdir=$remotebackupdir"
echo "remotebackuserver=$remotebackupserver"
echo "remotebackuserverport=$remotebackupserverport"
echo "backupdir=$backupdir"
echo "USER=$USER"
echo "DIRSOURCE1=$DIRSOURCE1"
echo "DIRSOURCE2=$DIRSOURCE2"
echo "DIRDESTI1=$DIRDESTI1"
echo "DIRDESTI2=$DIRDESTI2"
echo "PID=$PID"
echo "testorconfirm=$testorconfirm"

# Source
export SERVSOURCE=$remotebackupserver
export SERVPORTSOURCE=$remotebackupserverport
export DIRSOURCE1="$remotebackupdir/home*";
export DIRSOURCE2="$remotebackupdir/backup*";

# Target
export DIRDESTI1="$backupdir";
export DIRDESTI2="$backupdir";


echo `date +'%Y-%m-%d %H:%M:%S'`" Start to copy backups of backup on local server" 

if [ "x$remotebackupserver" == "x" ]; then
	echo "Usage:   ${0}  remotelogin  (test|confirm)  [--delete]"
	echo "Example: ${0}  admin        test"
	echo "Note:    The user running the script must have its public key declared on the backup server to backup"
	exit
fi

export errstring=""
export ret=0
export ret1=0
export ret2=0

cd "$scriptdir"

>/tmp/$script.log 

# Loop on each target server
for SERVSOURCECURSOR in `echo $SERVSOURCE | sed -e 's/,/ /g'`
do
	# Case of /mnt/diskbackup/home*x
	echo `date +'%Y-%m-%d %H:%M:%S'`" Do rsync of system backup on $SERVSOURCECURSOR:$DIRSOURCE1$i to $DIRDESTI1 ..."

	for i in 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j' 'k' 'l' 'm' 'n' 'o' 'p' 'q' 'r' 's' 't' 'u' 'v' 'w' 'x' 'y' 'z' '0' '1' '2' '3' '4' '5' '6' '7' '8' '9' ; do
		echo `date +'%Y-%m-%d %H:%M:%S'`" Process directory $SERVSOURCECURSOR:$DIRSOURCE1$i"
		export RSYNC_RSH="ssh -p $SERVPORTSOURCE"
		# Note for backup of backup of backup, we do not exclude backup_backups.exclude
		# So image is like the backup server.
		export command="rsync -x $OPTIONS $USER@$SERVSOURCECURSOR:$DIRSOURCE1$i $DIRDESTI1";
		echo "$command";

		> /tmp/$script.err
		$command >/tmp/$script.log 2>/tmp/$script.err
		if [ "x$?" != "x0" ]; then
	        nberror=`cat /tmp/$script.err | grep -v "Broken pipe" | grep -v "No such file or directory" | grep -v "some files/attrs were not transferred" | wc -l`
    	    cat /tmp/$script.err
			if [ "x$nberror" != "x0" ]; then
			  	echo "ERROR Failed to make rsync for $DIRSOURCE1$i"
		  		echo
		   		export ret1=$(($ret1 + 1));
		   		export errstring="$errstring\nDir $DIRSOURCE1$i "`date '+%Y-%m-%d %H:%M:%S'`
		   	else
                echo "No files found"
                echo
		   	fi
		else
			echo "OK"
			echo
		fi
	done

	echo End of copy of home dirs /mnt/diskbackup/home*x
	sleep 2

	export ret2=0
	if [ "x$ret1" == "x0" ]; then
		echo

		# Case of /mnt/diskbackup/backup*x
		echo `date +'%Y-%m-%d %H:%M:%S'`" Do rsync of customer directories on $SERVSOURCECURSOR:$DIRSOURCE2$i to $DIRDESTI2 ..."

		for i in 'a' 'b' 'c' 'd' 'e' 'f' 'g' 'h' 'i' 'j' 'k' 'l' 'm' 'n' 'o' 'p' 'q' 'r' 's' 't' 'u' 'v' 'w' 'x' 'y' 'z' '0' '1' '2' '3' '4' '5' '6' '7' '8' '9' ; do
				echo `date +'%Y-%m-%d %H:%M:%S'`" Process directory $SERVSOURCECURSOR:$DIRSOURCE2$i"

					# Test if we force backup on a given dir
					#if [ "x$2" != "x" ]; then
					#	if [ "x$2" != "xosu$i" ]; then
					#		break
					#	fi
					#fi

					export RSYNC_RSH="ssh -p $SERVPORTSOURCE"
					# Note for backup of backup of backup, we do not exclude backup_backups.exclude
					# So image is like the backup server.
			        export command="rsync -x $OPTIONS $USER@$SERVSOURCECURSOR:$DIRSOURCE2$i $DIRDESTI2";
		        	echo "$command";

					> /tmp/$script.err
			        $command >/tmp/$script.log 2>/tmp/$script.err
			        if [ "x$?" != "x0" ]; then
				        nberror=`cat /tmp/$script.err | grep -v "Broken pipe" | grep -v "No such file or directory" | grep -v "some files/attrs were not transferred" | wc -l`
    	    			cat /tmp/$script.err
						if [ "x$nberror" != "x0" ]; then
				        	echo "ERROR Failed to make rsync for $DIRSOURCE2$i"
				        	echo
				        	export ret2=$(($ret2 + 1));
			    	    	export errstring="$errstring\nDir $DIRSOURCE2$i "`date '+%Y-%m-%d %H:%M:%S'`
			    	    else
			                echo "No files found"
			                echo
			    	    fi
					else
						echo "OK"
						echo
			        fi

				echo
		done
		
		echo End of copy of home dirs /mnt/diskbackup/backup*x
	fi
	
	echo
	echo -e `date +'%Y-%m-%d %H:%M:%S'`" End ret1=$ret1 ret2=$ret2 errstring=$errstring"
	echo

done


if [ "x$ret1" != "x0" -o "x$ret2" != "x0" ]; then
	echo "Send email to $EMAILTO to inform about backup error ret1=$ret1 ret2=$ret2"
	
	#echo -e "Backup pulled of a backup for "`hostname`" failed - End ret1=$ret1 ret2=$ret2\n$errstring" | mail -aFrom:$EMAILFROM -s "[Warning] Backup pulled of a backup - "`hostname`" failed" $EMAILTO
	
	export body="Backup pulled of a backup for "`hostname`" failed - End ret1=$ret1 ret2=$ret2\n$errstring"
	export subject="[Warning] Backup pulled of a backup - "`hostname`" failed" 
	export headers="From: $EMAILFROM"
	/usr/bin/php -r "mail('$EMAILTO', '$subject', '$body', '$headers');"; 
	
	#if [ -s /usr/syno/bin/synodsmnotify ]; then
		#/usr/syno/bin/synodsmnotify "@administrators" "System Event" "$subject $body"; 
	#fi
	
	echo

	exit $ret
else 
	echo "Send email to $EMAILTO to inform about backup success"

	#echo -e "Backup pulled of a backup for "`hostname`" succeed - End ret1=0 ret2=0\n$errstring" | mail -aFrom:$EMAILFROM -s "[Backup pulled of a Backup - "`hostname`"] Backup pulled of a backup succeed" $EMAILTO

	export body="Backup pulled of a backup for "`hostname`" succeed - End ret1=$ret1 ret2=$ret2\n$errstring"
	export subject="[Backup pulled of a Backup - "`hostname`"] Backup pulled of a backup succeed" 
	export headers="From: $EMAILFROM\r\n"
	/usr/bin/php -r "mail('$EMAILTO', '$subject', '$body', '$headers');"; 

	#if [ -s /usr/syno/bin/synodsmnotify ]; then
		#/usr/syno/bin/synodsmnotify "@administrators" "System Event" "$subject $body";
	#fi
	
	echo
fi

exit 0
