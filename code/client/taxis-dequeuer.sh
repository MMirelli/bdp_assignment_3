#!/bin/bash

USAGE="$0 KAFKA_HOME [PARTITION] [OPTIONS] - fetches messages from kafka topic \"taxis_out\".\n\t 
	PARAMETERS:\n\t\t
	KAFKA_HOME - path to kafka main directory.\n\t\t
	PARTITION - integer indicating an existing partition for taxis_out, by default all of them are shown.\n\t
	OPTIONS: \n\t\t
	-h, --help - display help.
"

if [[ $1 = "--help" ]] || [[ $1 = "-h" ]]
then
   echo -e $USAGE
   exit 0
fi

KAFKA_HOME=$1

if [ -z $2 ]
then
    $KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic taxis_out --from-beginning 
else
    $KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic taxis_out --from-beginning --partition $2 

fi
