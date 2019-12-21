#!/bin/bash

USAGE="$0 [OPTIONS] - clears the specified authorized files from the current key and deletes it.\n\t 
	  OPTIONS:\n\t\t
	  -h, --help - display help.
"

if [[ $1 = "--help" ]] || [[ $1 = "-h" ]]
then
   echo -e $USAGE
   exit 0
fi

MSG="Please provide the path (including filename) to
     the ssh \"authorized_keys\" file, \n for ~/.ssh/authorized_keys"
echo $MSG
read -p "Path: " AUTH_KEYS_FILE

if [ -z $AUTH_KEYS_FILE ]
then
    AUTH_KEYS_FILE=~/.ssh/authorized_keys
fi


# if the authorized_keys exists then removes the key otherwise only the ./.ssh
if test -f $AUTH_KEYS_FILE
then
    echo "Clearing $AUTH_KEYS_FILE of the current key"
    # if $AUTH_KEYS_FILE contains a key except the current, this will be copied in tmp and from tmp back to authorized_keys, otherwise tmp will be empty.
    if grep -v "$(cat .ssh/bdp3_rsa.pub)" $AUTH_KEYS_FILE > ./.ssh/tmp
    then
	cat ./.ssh/tmp > $AUTH_KEYS_FILE && rm ./.ssh/tmp;
    else
	rm $AUTH_KEYS_FILE && rm ./.ssh/tmp;
  fi
fi

echo "Removing SSH keypair"
rm -r ./.ssh
