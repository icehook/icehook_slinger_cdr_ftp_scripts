#!/bin/bash

# change this to false (or anything but true) when not debugging
DEBUG="true"

# dont mess with this unless parameters change
USAGE="Usage:  $0 -u user -p password -a /absolute/path/to/cdrs/ -e cdrfile_extension"

FTPSERVER="slinger.icehook.com"

# so we dont have to comment out a hundered echo statements
function debug(){
  if [ "$DEBUG" = "true" ] ; then
   echo $1
  fi
}

# process the command line args
while getopts "u:p:a:e:" options; do
  case $options in
    u ) user=$OPTARG;;
    p ) pass=$OPTARG;;
    a ) path=$OPTARG;;
    e ) exten=$OPTARG;;
    h ) echo $USAGE;;
    \? ) echo $USAGE
         exit 1;;
    * ) echo $USAGE
          exit 1;;
  esac
done


# make sure we have the required args - show errors and exit if not
if [ -z $user ] ; then 
echo "ftp user is required"
quit="true"
fi
if [ -z $pass ] ; then 
echo "ftp password is required"
quit="true"
fi
if [ -z $path ] ; then 
echo "absolute path is required"
quit="true"
fi
if [ -z $exten ] ; then 
echo "cdrfile extension is required"
quit="true"
fi

if [ "$quit" = "true" ] ; then
echo $USAGE
exit 1
fi
processed="processed"

if [ ! -d "$path$processed" ]
then
debug "making directory for procesed files in $path$processed"
mkdir "$path$processed"
fi

# Ok our data should be setup now - so we can cd to where the CDR's are and start processing

#save the current directory
pwd=$(pwd)
debug "changing directory to $path"
cd $path

# push each cdrfile with the given extension - move it to a "backup" after we have pushed it
# connecting for each ftp session is not fast - but its the best way we can garauntee we 
# dont move any unpushed cdrfiles
for cdrfile in "*.$exten"
do
debug "pushing $cdrfile to $FTiPSERVER"
ftp -n $FTPSERVER <<-EOF
user $user $pass
put "$cdrfile"
EOF
debug "backing up $cdrfile"
mv $cdrfile processed/ 
done

cd "$pwd"
