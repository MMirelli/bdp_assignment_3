export LOCAL_DIR=$(pwd)
# TODO: next deployment step
export DATA_DIR=$LOCAL_DIR/../data
export LOGS_DIR=$LOCAL_DIR/../logs
export MYSIMBDP_DIR=$LOCAL_DIR/mysimbdp
export CLIENT_DIR=$LOCAL_DIR/client

export KAFKA_DIR=kafka-2.3.1
export KAFKA_HOME=$MYSIMBDP_DIR/$KAFKA_DIR
export PATH=$KAFKA_HOME/bin:$PATH

export HADOOP_DIR=hadoop-3.1.2
export HADOOP_HOME=$MYSIMBDP_DIR/$HADOOP_DIR
export PATH=$HADOOP_HOME/sbin:$HADOOP_HOME/bin:$PATH

export SPARK_DIR=spark-2.4.4
export SPARK_HOME=$MYSIMBDP_DIR/$SPARK_DIR
export PATH=$SPARK_HOME/bin:$PATH
# python deps for Spark
export PYDEPS=$MYSIMBDP_DIR/pydeps
export ZIP_PYDEPS=$MYSIMBDP_DIR/pydeps.zip
# configuration file temps
export CONF_FILES_DIR=$MYSIMBDP_DIR/conf_files

