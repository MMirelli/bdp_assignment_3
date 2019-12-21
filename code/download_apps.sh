#!/bin/bash

USAGE="$0 [OPTIONS] - Download the applications needed to run out bdp.\n\t 
	  OPTIONS:\n\t\t
	  -h, --help - display help.
"

if [[ $1 = "--help" ]] || [[ $1 = "-h" ]]
then
   echo -e $USAGE
   exit 0
fi

source app-env.sh

cd $MYSIMBDP_DIR

mkdir $KAFKA_HOME
wget http://mirror.netinch.com/pub/apache/kafka/2.3.1/kafka_2.11-2.3.1.tgz
tar xvf kafka_2.11-2.3.1.tgz -C $KAFKA_HOME --strip-components=1
rm kafka_2.11-2.3.1.tgz

mkdir $HADOOP_HOME
wget http://archive.apache.org/dist/hadoop/common/hadoop-3.1.2/hadoop-3.1.2.tar.gz
tar xvf hadoop-3.1.2.tar.gz -C $HADOOP_HOME --strip-components=1
rm hadoop-3.1.2.tar.gz

mkdir $SPARK_HOME
wget http://mirror.netinch.com/pub/apache/spark/spark-2.4.4/spark-2.4.4-bin-hadoop2.7.tgz
tar xvf spark-2.4.4-bin-hadoop2.7.tgz -C $SPARK_HOME --strip-components=1
rm spark-2.4.4-bin-hadoop2.7.tgz
