#!/bin/bash
# Online Backup program - any linux machine
# pay close attention to instance variables
# ------------------------------------------------------------------------------

usage="$(basename $0):file1 (filename of files to backup)"

# Make checks that the environment is complete
if [ $# -ne 0 ] ;then
    echo "I take no arguments"
    echo "USAGE: $usage"
    exit 1
fi

# Initialize variables
rootdir="/mnt/cifs_backup/$HOSTMANE"
backup="/root/scripts/conf/backup.conf"
error="/root/scripts/errors/file_dump_error"
>$error
err=0
machine=$(hostname|cut -f1 -d '.')
set $(date +"%b %d %Y")

# I used -j option on tar below
bufile="$rootdir/$machine-$1-$2-$3.tar.bz2"

# Check on structure
if [ ! -d /root/etc ] ; then
    echo "I created the /root/etc directory"
    mkdir /root/etc
fi

if [ ! -f $backup ] ; then
    echo "The file :$backup: does not exist"
    echo "You need to create a list of files to backup in '$backup'"
    exit 2
fi

if [ ! -d $rootdir ] ; then
    echo "I created the $rootdir directory"
    mkdir $rootdir
fi


# Create backup file
# The backup program allows wild card expansion
# ------------------------------------------------------------------------------

echo "I will loop through the list of files in $backup"
while read line
do
# Check for blank lines or commented lines
if ( ! echo "$line"|grep "^#" && ! echo "$line"|grep "^$") >/dev/null; then
    expandedline=$(echo $line)
    line="$expandedline"
        for i in $line
            do
            if [ -e "$i" ] ;then
                files_to_backup="$files_to_backup $i"
            else
                err=1
                echo $line >>$error
            fi
        done
fi
done <$backup

# j is bzip2
# z is gzip
tar -cjf $bufile $files_to_backup >/dev/null 2>&1
echo "A listing of files backed up"
tar -tjf $bufile
#bzip2 $bufile

if  [ "$err" -eq 1 ] ;then
    echo "YOU HAD ERRORS"
    echo "An error file is located in $error"
    echo "The following files were not found:"
    cat $error
else
    echo "OK - No errors"
fi

# Check for more than 3 files in $rootdir

sfiles=$(ls $rootdir/$machine*|wc -l)
if [ $sfiles -gt 2 ] ;then
    rfiles=$(ls -t $rootdir/$machine*| tail -n +3)  # inclusive of 3rd line
    for i in $rfiles
        do
        if [ -f $i ];then
            rm $i
        fi
    done
else
    echo "Less than 3 days of data stored"
fi

echo "Tar files retained in backup directory:"
ls -1 $rootdir/$machine*