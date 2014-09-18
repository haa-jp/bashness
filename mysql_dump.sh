#!/bin/bash
# Shell script to backup MySql database
# ------------------------------------------------------------------------------

MyUSER="root"           # USERNAME
MyPASS="password"       # PASSWORD
MyHOST="localhost"      # Hostname

# Linux bin paths, change this if it can not be autodetected via which command
#MYSQL="$(which mysql)"
#MYSQLDUMP="$MYSQL/bin/mysqldump"
#CHOWN="$(which chown)"
#CHMOD="$(which chmod)"
#GZIP="$(which gzip)"

MYSQL="//apps/mysql/bin/mysql"
MYSQLDUMP="//apps/mysql/bin/mysqldump"
CHOWN="//bin/chown"
CHMOD="//bin/chmod"
GZIP="//bin/gzip"

# Backup destination directory, change this if needed
#DEST="/mnt/cifs/dbbackups/"
DEST="/root/dumps"

# Main directory where backup will be stored
MBD="$DEST/mysql"

# Get hostname
HOST="$(hostname)"

# Get data in dd-mm-yyyy format
NOW="$(date +"%d-%m-%Y")"

# File to store current backup file
FILE=""
# Store list of databases
DBS=""

# DO NOT BACKUP these databases
IGGY="information_schema"

[ ! -d $MBD ] && mkdir -p $MBD || :

# Only root can access it!
$CHOWN 0.0 -R $DEST
$CHMOD 0600 $DEST

# Get all database list first
DBS="$($MYSQL -u $MyUSER -h $MyHOST -p$MyPASS -Bse 'show databases')"

for db in $DBS
do
    skipdb=-1
    if [ "$IGGY" != "" ];
    then
        for i in $IGGY
        do
            [ "$db" == "$i" ] && skipdb=1 || :
        done
    fi

    if [ "$skipdb" == "-1" ] ; then
        FILE="$MBD/$db.$HOST.$NOW.gz"
        # do all in one job pipe,
        # connect to mysql using mysqldump and pipe it out to gz file in backup dir 
        $MYSQLDUMP -u $MyUSER -h $MyHOST -p$MyPASS --lock-tables=false  $db | $GZIP -9 > $FILE
    fi
done