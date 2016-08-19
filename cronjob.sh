#!/bin/bash
PROCESSSCRIPT=../UKParlDataSheets-Scripts/process.php
PHP=`which php`
WGET=`which wget`
COMMONSFILE=Commons.xml
COMMONSSHEET=commonsV1.csv
LORDSFILE=Addresses.xml
LORDSSHEET=lordsV1.csv

rm $COMMONSFILE
rm $LORDSFILE

$WGET -q -O - http://data.parliament.uk/membersdataplatform/services/mnis/members/query/House=Commons/Addresses/ > $COMMONSFILE
$WGET -q -O - http://data.parliament.uk/membersdataplatform/services/mnis/members/query/House=Lords/Addresses/   > $LORDSFILE

if [[ -e $COMMONSFILE && -e $LORDSFILE ]]
then
  # Run the process on the XML files
  $PHP $PROCESSSCRIPT

  # Check if they changed
  IFS=$'\n'
  changes=($(git status -s))
  unset IFS

  modded=0

  # If they changed
  if [[ 1 -eq $(contains $COMMONSSHEET ${changes[@]}) ]]
  then
    git add $COMMONSSHEET
    modded=1
  fi

  if [[ 1 -eq $(contains $LORDSSHEET ${changes[@]}) ]]
  then
    git add $LORDSSHEET
    modded=1
  fi

  # Do a git commit and push
  if [[ 1 -eq $modded ]]
  then
    git commit -m 'Parliamentarian data updated by cronjob'
    git push
  fi
else
  echo "Problem downloading parliamentarian data, bailing" 1>&2
  exit 1
fi

# Utility function: given a string and an array, echo 1 if the 
# array contains an element that contains the string
contains() {
  argv=("$@")
  search=${argv[0]}
  unset argv[0]
  for i in "${argv[@]}"
  do
      if [[ "$i" =~ "$search" ]]
      then
         echo 1
      fi
  done
  return 0
}
