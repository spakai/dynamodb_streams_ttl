import json
import boto3
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ['TABLE_NAME']

def lambda_handler(event, context):
    logger.info("Event: %s", json.dumps(event))
    
    for record in event['Records']:
        if record['eventName'] == 'REMOVE':
            # Process the REMOVE event
            old_image = record['dynamodb']['OldImage']
            task_id = old_image['task_id']['S']
            ttl = old_image['ttl']['N']
            
            logger.info(f"Processing removed item with task_id: {task_id}, ttl: {ttl}, table: {TABLE_NAME}")
            
            # Add your task processing logic here
            # For example, you could send a notification, start another process, etc.
            
    return {
        'statusCode': 200,
        'body': json.dumps('Successfully processed REMOVE events')
    }