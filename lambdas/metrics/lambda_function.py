import boto3
import json
import logging
import psycopg2
import os
import time

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


def get_data_from_athena():
    athena_client = boto3.client("athena", region_name=region_name)

    athena_database = os.environ['ATHENA_DATABASE']
    s3_bucket = os.environ['S3_BUCKET']
    s3_folder = os.environ['S3_FOLDER']

    # SQL Files
    sql_query_file = os.path.join(os.environ['LAMBDA_TASK_ROOT'], 'sql_query.sql')
    sql_query = open_file(sql_query_file)

    # Execute the SQL query on Athena
    response = athena_client.start_query_execution(
        QueryString=sql_query,
        QueryExecutionContext={'Database': athena_database},
        ResultConfiguration={'OutputLocation': f"s3://{s3_bucket}/{s3_folder}/post_metrics_source"}
    )

    # Get the query execution ID
    query_execution_id = response['QueryExecutionId']

    # Wait for the query to complete
    while True:
        query_status = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
        status = query_status['QueryExecution']['Status']['State']

        if status == 'SUCCEEDED':
            logger.info("Query succeeded!")
            break
        elif status in ['FAILED', 'CANCELLED']:
            logger.error(f"Query {status.lower()}!")
            raise Exception(f"Query {status.lower()}: {query_status['QueryExecution']['Status']['StateChangeReason']}")
        else:
            logger.info("Waiting for query to complete...")
            time.sleep(5)  # Wait for 5 seconds before checking again

    # Fetch the query results
    result_response = athena_client.get_query_results(QueryExecutionId=query_execution_id)

    # Process and log the results
    rows = result_response['ResultSet']['Rows']
    headers = [col['VarCharValue'] for col in rows[0]['Data']]
    results = []

    for row in rows[1:]:
        data = [col['VarCharValue'] if 'VarCharValue' in col else None for col in row['Data']]
        results.append(dict(zip(headers, data)))

    structured_data = []

    logger.info("Start processing structured data")
    for result in results:
        platform = result['platform']
        username = result['username']
        for field in ['comments', 'likes', 'video_views', 'video_plays']:
            value = result[field]
            structured_data.append({
                "platform": 5 if platform == 'instagram' else platform,
                "username": username,
                "field": field,
                "value": value,
            })
    logger.info("Done processing structured data")
    
    # Log the results
    for result in results:
        logger.info(json.dumps(result))

    logger.info(structured_data[:5])

    return structured_data

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

def open_file(file_path):
    with open(file_path, 'r') as file:
        return file.read()

def lambda_handler(event, context):
    try:
        structured_data = get_data_from_athena()
        insert_data(structured_data)
        return {
            'statusCode': 200,
            'body': json.dumps(structured_data)
        }
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({"error": str(e)})
        }
