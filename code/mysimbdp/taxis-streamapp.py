from pyspark import SparkConf
from pyspark import SparkContext
from pyspark.sql import SparkSession
from pyspark.streaming import StreamingContext
from pyspark.streaming.kafka import KafkaUtils
from kafka import KafkaProducer
from py4j.protocol import Py4JJavaError
import time

# The workers execute the sum in parallel
def update_function(newValues, current_sum):
    if current_sum is None:
        current_sum = 0
    # add the new values with the previous
    # running count to get the new count
    return sum(newValues, current_sum)

# Here we deserialize the message in
def msg_handler(mdd):
    value = mdd.message.split(',')
    return (mdd.key, value)

# TODO: With a PoolConnection (static connection shared by
#       all executors we would reduce the overhead) 
def send_results_to_kafka(messages):
    # code executed by the single executor
    producer = KafkaProducer(bootstrap_servers='localhost:9092')

    for message in messages:
        to_bytes = lambda m: bytes( m, encoding='utf-8' )
        key_bytes = to_bytes(message[0])
        value_bytes = to_bytes( message[0] + ',' + str(message[1]) )
        
        producer.send('taxis_out', key=key_bytes, value=value_bytes)
        producer.flush()

def transform(message):
    try:
        return (message[0], float(message[1][9]))
    except ValueError:
        print ( "Input error")
        return (message[0], 0.0)
        
def main():
    # Task configuration.
    topic = "taxis_in"
    brokerAddresses = "localhost:9092"
    # TODO: reduce batchTime
    batchTime = 5

    spark = SparkSession. \
        builder. \
        appName("TaxisSumFares"). \
        getOrCreate()

    sc = spark.sparkContext
    ssc = StreamingContext(sc, batchTime)
    while True:
        try:
            # creating a kafka stream
            kvs = KafkaUtils. \
            createDirectStream(ssc=ssc, topics=[topic], \
                kafkaParams={"metadata.broker.list": brokerAddresses}, \
                messageHandler=msg_handler)
            
        except  Py4JJavaError as e:
            print(e)
            time.sleep(2)
        else:
            break
    # set checkpoint to recover from failures and keep the counter
    ssc.checkpoint("hdfs://localhost:9000/tmp")
    # extracting the valuable information (vendor_id, fare_amount)
    pairs = kvs.map(transform)

    # executing the sum of fare_amount by vendor_id
    rst = pairs.updateStateByKey(update_function)
    pairs.pprint()
    rst.pprint()
    # sending the stream to taxis_out
    rst.foreachRDD ( lambda rdd: rdd.foreachPartition(send_results_to_kafka) )
                     
    # Starting the task run.
    ssc.start()
    ssc.awaitTermination()

if __name__ == '__main__':
    main()
