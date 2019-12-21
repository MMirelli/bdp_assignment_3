import logging
import time
#from datetime import datetime
from time import gmtime, strftime
from kafka import KafkaProducer
from kafka.partitioner.base import Partitioner
import random
import time
import re
from kafka.errors import TopicAlreadyExistsError, NoBrokersAvailable
from kafka.admin import KafkaAdminClient, NewTopic
from kafka.client import KafkaClient
import argparse

arg_parser = argparse.ArgumentParser()

arg_parser.add_argument('--log_file', \
                        default='../logs/taxis-enqueuer-logs', \
                        help='Logs file path.', \
                        type=str)

arg_parser.add_argument('--data_file', \
                        default='../data/taxis.csv', \
                        help='Data file path.', \
                        type=str)

arg_parser.add_argument('--rows', \
                        default=10**5, \
                        help='How many rows the client sends.', \
                        type=str)

arg_parser.add_argument('--str_rate', \
                        default=10**-5, \
                        help='What streaming rate (s/messages) the client sends the messages.', \
                        type=str)

arg_parser.add_argument('--error_n', \
                        default=0, \
                        help="""The number of wrong(messages/s) the
                                client sends (it will be always less than rows).""", \
                        type=str)

arg_parser.add_argument('--offset', \
                        default=0, \
                        help="""Offset in reading the file.""", \
                        type=str)



args = arg_parser.parse_args()

LOGS_FILE = args.log_file
DATA_FILE = args.data_file

N_ROWS = int(args.rows)
STR_RATE = float(args.str_rate)
OFFSET = int(args.offset)

ERROR_N = int(args.error_n)
ERROR_TMP = ERROR_N

format = " [%(levelname)s] %(asctime)s >> [%(name)s] %(message)s"

logging.basicConfig(format=format, filename=LOGS_FILE, filemode='w+',
                    datefmt="%H:%M:%S", level=logging.DEBUG)

logger = logging.getLogger('producer')

def add_error(message):
    global ERROR_TMP
    if ERROR_TMP > 0:
        contains_err = int(round(random.random()))
        if contains_err == 1:
            logger.info("Inserting an error in the current message.")
            values = message.split(',')
            error = "ERROR"
            logger.info(values[9] + " will be modified by " + error)
            values[9] = error
            message = ','.join(values)
            ERROR_TMP -= 1
        else:
            logger.info("The current message contains no errors")
    return message


def publish_message(producer_instance, topic_name, key, value):
    # dt = datetime.now()
    # value = value[0:len(value)-2]
    # value += ',' + str(dt)
    
    # it adds error to the significant part of the message, randomly
    value = add_error(value)
    
    key_bytes = bytes(key, encoding='utf-8')
    value_bytes = bytes(value, encoding='utf-8')

    producer_instance.send(topic_name, key=key_bytes, value=value_bytes)
    producer_instance.flush()
    logger.info("Key: '{0}', value: '{1}' published successfully on topic '{2}'.".format(key, value, topic_name))

        
def connect_kafka_producer():
    _producer = None
    try:
        logger.info("Connecting to kafka")
        _producer = KafkaProducer(
            bootstrap_servers=['localhost:9092'])
        
    except Exception as ex:
        logger.debug(ex)
    finally:
        return _producer
    
def main():
    
    SERVER_IP = "localhost:9092"
    
    while True:
        try:
            admin_client = KafkaAdminClient( \
                    bootstrap_servers=SERVER_IP, \
                    client_id='test')
            
        except NoBrokersAvailable:
            logger.info('No broker available, retrying')
            time.sleep(2)
        else:
            logger.info("Connection to %s succeeded." % SERVER_IP)
            break

#    should take the topic name from a json, as well as the num_partitions and rf
    logger.info("Sending "+str(N_ROWS)+" at a rate " + \
                str(STR_RATE) + " and error rate " + \
                str(ERROR_N) + " and offset " + str(OFFSET) )
    rf = 1
    kafka_producer = connect_kafka_producer()
    i = 0
    
    with open(DATA_FILE, 'r') as f:
        head = f.readline()
        while (i < N_ROWS + OFFSET):
            i += 1
            line = f.readline()
            if( i > OFFSET ):
                fst_comma_i = line.find(',')
                key = line[0:fst_comma_i]
                value = line[fst_comma_i+1:len(line)]
                publish_message(kafka_producer,
                                'taxis_in', key, value)
            time.sleep(STR_RATE)

    logger.info("The number of sent messages containing an error is " + \
                str(ERROR_N-ERROR_TMP))


if __name__ == '__main__':
    main()
