#!/bin/bash

# change this to false (or anything but true) when not debugging
DEBUG=true

# dont modify this unless parameters change
USAGE="Usage: $0 -k /absolute/path/preprocessor.awk -u user -p password -a /absolute/path/cdrs -d /absolute/path/processed/cdrs -e extension(ex: csv)"

FTPSERVER="ftp://ftp1.slinger.icehook.com"

CURL="/usr/bin/curl"

AWK="/usr/bin/awk"

TMP_DIR="/tmp/curl_ftp"

PROCESSED_STRING="v2"

function debug() {
  if [[ $DEBUG ]] ; then
   echo $1
  fi
}

# process the command line args
while getopts "k:u:p:a:e:d:" options; do
  case $options in
    k ) preprocessor=$OPTARG;;
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
    quit=true
fi

if [ -z $pass ] ; then
    echo "ftp password is required"
    quit=true
fi

if [ -z $path ] ; then
    echo "absolute cdr path is required"
    quit=true
fi

if [ -z $processed_path ] ; then
    echo "absolute processed cdr path is required"
    quit=true
fi

if [ -z $ext ] ; then
    echo "cdr extentions required ex: csv"
    quit=true
fi

if [[ $quit ]] ; then
    echo $USAGE
    exit 1
fi

if [[ ! $ext =~ "^." ]] ; then
    ext=".$ext"
fi

if [ ! -d "$TMP_DIR" ] ; then
    debug "making directory for preprocessing files in $TMP_DIR"
    mkdir -p "$TMP_DIR"
fi

if [ ! -d "$processed_path" ] ; then
    debug "making directory for processed files in $processed_path"
    mkdir -p "$processed_path"
fi

debug "looking for files ending in $ext in $path"

# push each cdrfile with the given extension - move it to a "backup" after we have pushed it
# connecting for each ftp session is not fast - but its the best way we can garauntee we
# dont move any unpushed cdrfiles
for cdr_file in `find "$path" -type f -regextype sed -regex "^.*$ext$"`
do
  original_cdr_file="$cdr_file"
  filename=$(basename "$cdr_file")
  base_filename="${filename%$ext}"

  if [ $preprocessor ] ; then
    output_file="$TMP_DIR/$base_filename-$PROCESSED_STRING$ext"

    debug "preprocessing $cdr_file with output going to $output_file"
    echo "$AWK -f $preprocessor $cdr_file > $output_file"

    $AWK -f $preprocessor $cdr_file > $output_file

    if [ $? = "0" ] ; then
      debug "successful preprocessing of $cdr_file"
      cdr_file=$output_file
    else
      echo "failed preprocessing of $cdr_file" >> slinger_ftp.err
      echo "failed preprocessing of $cdr_file"
      exit 1
    fi
  fi

  debug "pushing $cdr_file to $FTPSERVER"

  $CURL -T $cdr_file $FTPSERVER --user $user:$pass >> slinger_ftp.out 2>> slinger_ftp.err

  if [ $? = "0" ] ; then
    debug "successful upload of $cdr_file"
    debug "backing up $original_cdr_file"
    mv "$original_cdr_file" "$processed_path"
    debug "deleting $cdr_file"
    rm "$cdr_file"
  else
    echo "failed uploading $cdr_file" >> slinger_ftp.err
    debug "failed uploading $cdr_file"
  fi
done


