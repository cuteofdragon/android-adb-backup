#!/bin/bash

# License; Apache-2

# Tested/Fixed for Android O by marc_soft@merlins.org 2017/12

set -e   # fail early

A="adb -d"

DRY="echo"
if [[ "$1" == "--doit" ]]; then DRY=""; shift; fi
DIR="$1"
shift

if [[ ! -d "$DIR" ]]; then
	echo "Usage: $0 [--doit] <date-dir>"
	echo "Must be created with ./backup_system_apps.sh"
	echo "Will be dry run by default unless --doit is given"
	exit 2
fi

cd $DIR

if [ $# -gt 0 ]; then
	APPS="$@"
	echo "## Push apps: $APPS"
else
	APPS=$(echo data/*)
	echo "## Push all apps in $DIR: $APPS"
fi


echo "## Restart adb as root"
$A root
sleep 3

for i in $APPS
do
	APP="$(basename $i)"
	echo "Attempting to restore data for $APP"
	# figure out current app user id
	if ! L=( $($A shell ls -d -l /data/data/$APP) ); then
		echo "ERROR: cannot restore $APP, not installed on device"
	else
		# drwx------ 10 u0_a240 u0_a240 4096 2017-12-10 13:45 .
		# => return u0_a240
		ID=${L[2]}
                echo "User id => $ID"
                
                if ! $A shell "mkdir /data/data/$APP/.backup"; then
			echo "ERROR: Cannot create backup dir, skipping app $APP"
			continue
		fi
		echo "Backup $APP data to /data/data/$APP/.backup"
                $DRY $A shell "mv /data/data/$APP/{*,.backup}"
                $DRY $A push data/$APP /data/data/

		(cd "data/$APP"
		# support directories like "Crash Reports"
		export IFS="
		"
		for j in `find . -printf "%P\n"`; 
		do
		    if [[ -d "$DIR/$j" ]]; then
			$DRY $A shell "mkdir -p \"/data/data/$APP/$j\""
		    fi
		    #echo "Fixing permissions on $j"
		    #test -z "$DRY" && echo $A shell chown $ID.$ID "/data/data/$APP/$j"
		    #$DRY $A shell chown $ID.$ID "\"/data/data/$APP/$j\""
		done )

                $DRY $A shell "chown -R $ID.$ID /data/data/$APP/*" || true
	fi
done

[[ -n $DRY ]] && echo "==== This is DRY MODE. Use --doit to actually copy."
