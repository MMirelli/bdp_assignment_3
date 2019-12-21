#!/bin/bash

USAGE="$0 [OPTIONS] [[CLIENT_N DATA_FILE N_MESSAGES STR_RATE] ERROR_RATE] - starts the application, Ctrl-C will cause the whole application to terminate.\n\t 
	  OPTIONS:\n\t\t
	  -h, --help - display help.\n\t
	  PARAMETERS:\n\t\t
	  CLIENT_N   - (int) Number of clients ingesting streamed data.\n\t\t\t
	  	       Default: 1 \n\t\t
	  DATA_FILE  - (str) Name of the file in \"../data\" which we want 
	  	       to use for streaming. \n\t\t\t
		       Default: taxis.csv \n\t\t
	  OFFSET     - (int) offset used to read the data, if set greater than 0 the clients do not read the same data. 
	  	       Be aware of the file dimension though.\n\t\t\t
	  	       Default: 0\n\t\t
	  N_MESSAGES - (int) Number of messages the customers send.\n\t\t\t
	  	       Default: 10000\n\t\t
	  STR_RATE   - (float) Streaming rate (s/message).\n\t\t\t
	  	       Default: 0.00001 \n\t\t
	  ERROR_N - (int) Number of errors in input stream
	  	        (always less than N_MESSAGES).\n\t\t\t
			Default: 0
"

if [[ $1 = "--help" ]] || [[ $1 = "-h" ]]
then
   echo -e $USAGE
   exit 0
fi

ERROR_N="0"
if [ $1 ] && [ $2 ] && [ $3 ] && [ $4 ] && [ $5 ]
then
    CLIENT_N=$1
    DATA_FILE=$2
    OFFSET=$3
    N_MESSAGES=$4
    STR_RATE=$5
    
    if [[ $6 ]]
    then
	ERROR_N=$6
    fi
else
    CLIENT_N=1
    DATA_FILE="taxis.csv"
    OFFSET=0
    N_MESSAGES="10000"
    STR_RATE="0.00001"
fi

interrupted() {
    echo "Ctrl-C pressed application terminating."
    $LOCAL_DIR/stop_app.sh $1 $2
    exit 130
}

export TOPIC_IN_NAME=taxis_in
export TOPIC_OUT_NAME=taxis_out

# in case of Ctrl-C it will stop the application
trap ' interrupted $TOPIC_IN_NAME $TOPIC_OUT_NAME ' INT

source app-env.sh # gets the environment variables

# it gets executed only the first startup after that the SSH_PORT will be stored in app-env.sh
if [[ -z $SSH_PORT ]]
then
# gets the port number
   MSG="Please start ssh server and agent on your machine, insert
     	       port number, \n for default (22)."
   echo $MSG
   read -p "SSH port number: " SSH_PORT 

   # tells if it not an integer
   if [ $((SSH_PORT)) !=  $SSH_PORT 2>/dev/null ]
   then
       echo "Port number must be an integer. Terminating."
       exit -1
   fi

   # user inserted \n
   if [ -z $SSH_PORT ]
   then
       echo "No port number inserted, using default."
       SSH_PORT=22
   fi
   # set env for ssh ports
   export HADOOP_SSH_OPTS="-p $SSH_PORT"
   export SPARK_SSH_OPTS="-p $SSH_PORT"
   # write on env-app.sh vars just set
   echo "export SSH_PORT=$SSH_PORT" >> app-env.sh
   echo "export HADOOP_SSH_OPTS=\"$HADOOP_SSH_OPTS\"" >> "app-env.sh"
   echo "export SPARK_SSH_OPTS=\"$SPARK_SSH_OPTS\"" >> "app-env.sh"
fi

# TODO: comment
#./stop_app.sh $TOPIC_IN_NAME $TOPIC_OUT_NAME

if test ! -d $PYDEPS
then
    mkdir $PYDEPS
    # preparing the python dependencies for Spark
    pip3 install --target $PYDEPS -r $MYSIMBDP_DIR/requirements.txt
    cd $PYDEPS
    zip -r $ZIP_PYDEPS ./
    cd $LOCAL_DIR
fi

if [[ -z $JAVA_HOME ]]
then
    echo "JAVA_HOME not set, please set it according to the doc"
    exit 1
fi
echo "export JAVA_HOME=$JAVA_HOME" >> $CONF_FILES_DIR/hd/hadoop-env.sh

cp -f $CONF_FILES_DIR/hd/* $HADOOP_HOME/etc/hadoop/
[[ $? = 0 ]] && echo "Hadoop configuration files copied."

cp -f $CONF_FILES_DIR/sp/* $SPARK_HOME/conf/
[[ $? = 0 ]] && echo "Spark configuration files copied"

cp -f $CONF_FILES_DIR/kf/* $KAFKA_HOME/config/
[[ $? = 0 ]] && echo "Kafka configuration files copied."

# letting copying files
sleep 1

hdfs namenode -format
$HADOOP_HOME/sbin/start-dfs.sh

export TOPIC_PARTITIONS=2

nohup zookeeper-server-start.sh \
      $KAFKA_HOME/config/zookeeper.properties > \
      $LOGS_DIR/zookeeper-logs &

nohup kafka-server-start.sh \
      $KAFKA_HOME/config/server.properties > \
      $LOGS_DIR/kafka-logs &

sleep 2

# adding input topic
kafka-topics.sh --zookeeper localhost:2181 \
		--create --topic $TOPIC_IN_NAME \
		--partitions $TOPIC_PARTITIONS --replication-factor 1
# adding output topic
kafka-topics.sh --zookeeper localhost:2181 \
		--create --topic $TOPIC_OUT_NAME \
		--partitions $TOPIC_PARTITIONS --replication-factor 1

# starts spark master and slaves, as per configuration files in CONFIG_FILES_DIR/sp/
$SPARK_HOME/sbin/start-all.sh
# letting spark start
sleep 2

$SPARK_HOME/bin/spark-submit --master spark://localhost:7077 \
			     --py-files $ZIP_PYDEPS \
			     --packages  org.apache.spark:spark-streaming-kafka-0-8_2.11:2.4.4 \
			     --verbose $MYSIMBDP_DIR/taxis-streamapp.py \
			     --driver-java-options "-Dlog4j.configuration=file://$SPARK_HOME/conf/log4j.properties" \
			     --executor-java-options "-Dlog4j.configuration=file://$SPARK_HOME/conf/log4j.properties" \
			     >> $LOGS_DIR/spark-logs &

read -p "When spark is ready press enter to start the customer enqueuer"

i=0
while [ $i -lt $CLIENT_N ]
do
    i=$[$i+1]
    # Starts the clients pushing data in Kafka
    python3 $CLIENT_DIR/taxis-enqueuer.py \
	    --log_file=$LOGS_DIR/taxis-enqueuer-logs \
	    --data_file=$DATA_DIR/$DATA_FILE \
	    --rows=$N_MESSAGES --str_rate=$STR_RATE \
	    --error_n=$ERROR_N --offset=$(( $OFFSET * $i )) &
    echo "Client $i started"
done
echo "$CLIENT_N clients are ingesting $N_MESSAGES messages at a streaming rate $STR_RATE (s/messages) and error rate of $ERROR_N (errors/total). File used: $DATA_DIR/$DATA_FILE"


# customer starts fetching data
$CLIENT_DIR/taxis-dequeuer.sh $KAFKA_HOME
