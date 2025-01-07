import boto3
import csv
import io
import json
import logging
import os
import psycopg2

from datetime import datetime
from typing import List, Dict

logger = logging.getLogger()
logger.setLevel(logging.INFO)

region_name = "us-west-1"

def get_secret():
    secret_name = os.environ("SECRET_NAME")

    client = boto3.client('secretsmanager', region_name=region_name)

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except Exception as e:
        print(f"Error fetching secret: {e}")
        raise e
    
    secret = get_secret_value_response['SecretString']
    return json.loads(secret)


def get_cursor():
    secret = get_secret()

    rds_host = secret['RDS_HOST']
    rds_db_name = secret['RDS_DB_NAME']
    rds_user = secret['RDS_USER']
    rds_password = secret['RDS_PASSWORD']
    rds_port = os.getenv('RDS_PORT', '5432')

    try:
        logger.info(f"Attempting to connect to RDS at {rds_host}:{rds_port} using database {rds_db_name}")
        connection = psycopg2.connect(
            host=rds_host,
            database=rds_db_name,
            user=rds_user,
            password=rds_password,
            port=rds_port
        )
        logger.info("Connection to RDS established successfully")
        return connection, connection.cursor()

    except psycopg2.OperationalError as oe:
        logger.error(f"OperationalError while connecting to the database: {oe}")
        raise oe


def insert_data(structured_data: List[Dict]):
    try:
        connection, cursor = get_cursor()

        insert_query = """
        INSERT INTO discovery_metric ("date", "field", "value", "platform_user_id")
        VALUES (%s, %s, %s, %s)
        """
        
        for data in structured_data[:5]:  # Limit to 5 rows for insertion
            logger.info(f"Inserting data: {data}")
            cursor.execute(insert_query, (
                datetime.now(),
                data['field'],
                float(data['value']),
                data['platform']
            ))

        logger.info("Committing the transaction")
        connection.commit()

    except psycopg2.OperationalError as oe:
        logger.error(f"OperationalError while connecting to the database: {oe}")
        return {
            'statusCode': 500,
            'body': f"OperationalError: {str(oe)}"
        }

    except Exception as e:
        logger.error(f"Error connecting to database or inserting data: {e}")
        return {
            'statusCode': 500,
            'body': str(e)
        }

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
            logger.info("Connection to RDS closed")

def get_data(event, context):
    s3_bucket = os.environ.get('S3_BUCKET')
    s3_folder = os.environ.get('S3_FOLDER')

    if not s3_bucket or not s3_folder:
        logger.error("The surrounding variables S3_BUCKET or S3_FOLDER are not configured.")
        return {
            'statusCode': 400,
            'body': "Error: S3_BUCKET or S3_FOLDER are not configured."
        }

    logger.info(f"Searching files in S3 Bucket: {s3_bucket} inside the folder: {s3_folder}")

    s3 = boto3.client('s3')

    try:
        response = s3.list_objects_v2(Bucket=s3_bucket, Prefix=s3_folder)

        if 'Contents' not in response or not response['Contents']:
            logger.error(f"No files found in path {s3_folder} inside the bucket {s3_bucket}.")
            return {
                'statusCode': 404,
                'body': f"No files found in path {s3_folder}."
            }

        files = [content['Key'] for content in response['Contents'] if content['Key'].endswith('.csv')]
        
        if not files:
            logger.error(f"No CSV files found in path {s3_folder}.")
            return {
                'statusCode': 404,
                'body': f"No CSV files found in path {s3_folder}."
            }

        logger.info(f"CSV files found: {files}")

        headers_array = []
        data_array = []
    
        for file in files:
            try:
                csv_file = s3.get_object(Bucket=s3_bucket, Key=file)
                csv_content = csv_file['Body'].read().decode('utf-8')

                csv_reader = csv.reader(io.StringIO(csv_content))
                csv_iterator = iter(csv_reader)

                headers = next(csv_iterator, None)
                if headers:
                    headers_array = headers
                
                for row in csv_iterator:
                    data_array.append(row)
                
                logger.info(f"Finished processing file: {file}")
                
            except Exception as e:
                logger.error(f"Error processing file {file}: {str(e)}")
                raise
        
        logger.info(f"Total rows collected: {len(data_array)}")
        
        structured_data = []
        
        logger.info("Start processing structured data")
        for row in data_array:
            platform = row[0]
            username = row[1]
            for index, field in enumerate(headers_array[2:], start=2):
                value = row[index]
                structured_data.append({
                    "platform": 5 if platform == 'instagram' else platform,
                    "username": username,
                    "field": field,
                    "value": value,
                })
        logger.info("Done processing structured data")
        
        logger.info(structured_data[:5])
        
        return structured_data

    except Exception as e:
        logger.error(f"Error accessing S3 bucket: {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Error accessing S3 bucket: {str(e)}"
        }

def lambda_handler(event, context):
    structured_data = get_data(event, context)
    if isinstance(structured_data, dict):
        return structured_data  # Error already handled in get_data
    insert_data(structured_data)

    return {
        'statusCode': 200,
        'body': structured_data
    }
