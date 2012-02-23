#!/bin/bash

# change this to false (or anything but true) when not debugging
DEBUG="true"

# dont modify this unless parameters change
USAGE="Usage: $0 -u user -p password -a /absolute/path/to/cdrs/ -d /absolute/path/to/processed/cdrs/ -e extension"

FTPSERVER="ftp://ftp1.slinger.icehook.com"

function debug() {
  if [ "$DEBUG" = "true" ] ; then
   echo $1
  fi
}

# process the command line args
while getopts "u:p:a:e:d:" options; do
  case $options in
    u ) user=$OPTARG;;
    p ) pass=$OPTARG;;
    a ) path=$OPTARG;;
    d ) processed_path=$OPTARG;;
    e ) ext=$OPTARG;;
    h ) echo $USAGE;;
    \? ) echo $USAGE
         exit 1;;
    * ) echo $USAGE
          exit 1;;
  esac
done


# ensure the required args - show errors and exit if not
if [ -z $user ] ; then 
    echo "ftp user is required"
    quit="true"
fi

if [ -z $pass ] ; then 
    echo "ftp password is required"
    quit="true"
fi

if [ -z $path ] ; then
    echo "absolute cdr path is required"
    quit="true"
fi

if [ -z $processed_path ] ; then
    echo "absolute processed cdr path is required"
    quit="true"
fi

if [ "$quit" = "true" ] ; then
    echo $USAGE
    exit 1
fi

if [ ! -d "$processed_path" ] ; then
    debug "making directory for processed files in $processed_path"
    mkdir "$processed_path"
fi

# push each cdrfile with the given extension - move it to a "backup" after we have pushed it
# connecting for each ftp session is not fast - but its the best way we can garauntee we 
# dont move any unpushed cdrfiles
for cdr_file in `find $path -type f -name "*$ext"`
do
debug "pushing $cdr_file to $FTPSERVER"

curl -T $cdr_file $FTPSERVER --user $user:$pass >> slinger_ftp.out 2>> slinger_ftp.err

EXITSTATUS=$?
if [ "$EXITSTATUS" = "0" ] ; then
  debug "successful upload of $cdr_file"
  debug "backing up $cdr_file"
  mv $cdr_file $processed_path
else
  debug "failed uploading $cdr_file"
fi
done

