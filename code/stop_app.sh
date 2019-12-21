#!/bin/bash

USAGE=" "$0" TOPIC_IN_NAME TOPIC_OUT_NAME [OPTIONS] - it stops the whole application in the following order: spark, kafka, zookeeper. \n\t
	PARAMETERS:\n\t\t
	TOPIC_IN_NAME - name of the input topic to be deleted in shutdown.\n\t\t
	TOPIC_OUT_NAME - name of the output topic to be deleted in shutdown.\n\t
	OPTIONS: \n\t\t
	-h, --help - display help.
"

if [ $# == 0 ] || [ $1 = "--help" ] || [ $1 = "-h" ]
then
    echo -e $USAGE
    exit 0
fi

ENVS_FILE=app-env.sh

# change hostname
source $ENVS_FILE

$SPARK_HOME/sbin/stop-slave.sh localhost:7077
$SPARK_HOME/sbin/stop-master.sh 

kill -9 $(ps -aux | grep taxis-enqueuer.py | awk '{print $2}')

FINAL_SLEEP=0


jps -l | grep zookeeper
if [[ $? = 0 ]]
then
    $KAFKA_HOME/bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic $1 --if-exists

    $KAFKA_HOME/bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic $2 --if-exists
    sleep 2
    FINAL_SLEEP=5
fi

$KAFKA_HOME/bin/kafka-server-stop.sh

# giving the time to zookeeper to update the metadata for fresh reset
sleep $FINAL_SLEEP
$KAFKA_HOME/bin/zookeeper-server-stop.sh

$HADOOP_HOME/sbin/stop-all.sh

# clearing hadoop temps needed to startup and shutdown smoothly
rm -rf /tmp/hadoop*
# clearing spark jars
rm -rf $SPARK_HOME/work/*
rm -rf $KAFKA_HOME/logs/*

if test -f $ENVS_FILE
then
    # if $AUTH_KEYS_FILE contains a key except the current, this will be copied in tmp and from tmp back to authorized_keys, otherwise tmp will be empty.
    if grep "SSH_PORT" $ENVS_FILE
    then
	echo "Clearing app-env of SSH_PORT"
	head -n -3 $ENVS_FILE > .tmp
	cat .tmp > $ENVS_FILE
	rm .tmp
    fi
fi

if test -f $CONF_FILES_DIR/hd/hadoop-env.sh
then
    # if $AUTH_KEYS_FILE contains a key except the current, this will be copied in tmp and from tmp back to authorized_keys, otherwise tmp will be empty.
    if grep "JAVA_HOME" $CONF_FILES_DIR/hd/hadoop-env.sh
    then
	echo "Clearing hadoop-env of JAVA_HOME"
	head -n -1 $CONF_FILES_DIR/hd/hadoop-env.sh > .tmp
	cat .tmp > $CONF_FILES_DIR/hd/hadoop-env.sh
	rm .tmp
    fi
fi
