#!/bin/bash

USAGE="$0 [OPTIONS] - creates .ssh/bdp3_rsa key pair used to connect to localhost:<PORT_NUMBER> in order to start up HDFS and Spark in standalone mode.\n\t 
	  OPTIONS:\n\t\t
	  -h, --help - display help.
"

if [[ $1 = "--help" ]] || [[ $1 = "-h" ]]
then
   echo -e $USAGE
   exit 0
fi


# in this case we should generate a ssh keypair to setup HDFS and Spark in standalone mode, setting the authorized_keys file too, otherwise we don't
if [ ! -d .ssh ]
then
    echo "SSH session not initialized setting up ssh keypair."
    echo "Creating ./.ssh"
    mkdir ./.ssh
    
    # generates a key pair with no passphrase in ./.ssh/bdp3_rsa
    ssh-keygen -t rsa -P '' -f ./.ssh/bdp3_rsa
    chmod 0600 .ssh/bdp3_rsa.pub
    
    MSG="Please provide the path (including filename) to
     the ssh \"authorized_keys\" file, \n for ~/.ssh/authorized_keys"
    echo $MSG
    read -p "Path: " AUTH_KEYS_FILE

    echo $AUTH_KEYS_FILE
    # sending key to the master
    if [ -z $AUTH_KEYS_FILE ]
    then
	AUTH_KEYS_FILE=~/.ssh/authorized_keys
    fi
    cat ./.ssh/bdp3_rsa.pub >> $AUTH_KEYS_FILE
fi
