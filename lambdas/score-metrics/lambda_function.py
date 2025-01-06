import boto3
import json
import os
import time
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def open_file(file_path: str) -> str:
    try:
        with open(file_path, 'r') as sql_file:
            return sql_file.read()
    except FileNotFoundError:
        return {
            'statusCode': 500,
            'body': f'Error: The file {file_path} was not found.'
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error reading the file: {str(e)}'
        }


def lambda_handler(event, context):
    # Clients
    athena_client = boto3.client("athena",region_name="us-east-1")
    glue_client = boto3.client("glue", region_name='us-west-1')
    crawler_client = boto3.client("glue", region_name='us-east-1')

    # Args
    crawler_name = 'postscoremetrics-crawler'
    crawler_avg_name = 'postscoreavgmetrics-crawler'
    database = os.environ['ATHENA_DATABASE']
    s3_bucket = os.getenv("SOURCE_BUCKET")
    filetype = os.environ["FILETYPE"]
    glue_job_name = os.environ['GLUE_JOB_NAME']
    query_results_path = os.environ['QUERY_RESULTS_PATH']
    output_location = f"s3://{s3_bucket}/{query_results_path}".lower()

    # SQL Files
    sql_query_file = os.path.join(os.environ['LAMBDA_TASK_ROOT'], 'sql_query.sql')
    avg_sql_query_file = os.path.join(os.environ['LAMBDA_TASK_ROOT'], 'sql_query_average.sql')
                                 
    sql_query = open_file(sql_query_file)

    # Execute the SQL query on Athena
    response = athena_client.start_query_execution(
        QueryString=sql_query,
        QueryExecutionContext={'Database': database},
        ResultConfiguration={'OutputLocation': f"{output_location}/score_metrics_source"}
    )

    # Get the query execution ID
    query_execution_id = response['QueryExecutionId']
    
    # Wait for the query to complete
    while True:
        query_status = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
        status = query_status['QueryExecution']['Status']['State']
        
        if status == 'SUCCEEDED':
            print("Query succeeded!")
            break
        elif status in ['FAILED', 'CANCELLED']:
            print(f"Query {status.lower()}!")
            raise Exception(f"Query {status.lower()}: {query_status['QueryExecution']['Status']['StateChangeReason']}")
        else:
            print("Waiting for query to complete...")
            time.sleep(5)  # Wait for 5 seconds before checking again
    
    # Convert the SQL query output to filetype
    try:

        glue_response = glue_client.start_job_run(
            JobName=glue_job_name,
            Arguments={
                '--SOURCE_PATH': f"{output_location}/score_metrics_source",
                '--TARGET_FORMAT': f'{filetype}',
                '--TARGET_S3_BUCKET': s3_bucket,
                '--TARGET_S3_PATH': f"{output_location}/score_metrics"
            }
        )
        job_run_id = glue_response['JobRunId']
        print(f"Started Glue job: {glue_response['JobRunId']}")
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f"Error starting Glue job: {str(e)}"
        }
    
    # Wait for the Glue job to complete
    while True:
        job_status_response = glue_client.get_job_run(JobName=glue_job_name, RunId=job_run_id)
        job_status = job_status_response["JobRun"]["JobRunState"]

        if job_status == "SUCCEEDED":
            print("Glue job succeeded!")
            break
        elif job_status in ["FAILED", "STOPPED"]:
            print(f"Glue job {job_status.lower()}!")
            raise Exception(f"Glue job {job_status.lower()}: {job_status_response['JobRun']['ErrorMessage']}")
        else:
            print("Waiting for Glue job to complete...")
            time.sleep(10)  # Wait for 10 seconds before checking again


    # Start the crawler
    try:
        crawler_client.start_crawler(Name=crawler_name)
        print(f"Crawler '{crawler_name}' started successfully.")
    except crawler_client.exceptions.CrawlerRunningException:
        print(f"Crawler '{crawler_name}' is already running.")
        return {
            'statusCode': 400,
            'body': f"Crawler '{crawler_name}' is already running."
        }
    except Exception as e:
        print(f"Failed to start crawler '{crawler_name}': {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Failed to start crawler '{crawler_name}': {str(e)}"
        }
    
    # Wait for the crawler to complete
    while True:
        response = crawler_client.get_crawler(Name=crawler_name)
        crawler_state = response['Crawler']['State']
        
        if crawler_state == 'READY' or crawler_state == 'STOPPING':
            print(f"Crawler '{crawler_name}' completed successfully.")
            break
        elif crawler_state == 'RUNNING':
            print(f"Waiting for crawler '{crawler_name}' to complete...")
            time.sleep(30)  # Wait for 30 seconds before checking again
        else:
            print(f"Crawler '{crawler_name}' is in an unexpected state: {crawler_state}")
            return {
                'statusCode': 500,
                'body': f"Crawler '{crawler_name}' failed or is in an unexpected state: {crawler_state}"
            }
    

    avg_sql_query = open_file(avg_sql_query_file)
    
     # Execute the SQL query on Athena
    response = athena_client.start_query_execution(
        QueryString=avg_sql_query,
        QueryExecutionContext={'Database': database},
        ResultConfiguration={'OutputLocation': f"{output_location}/score_avg_metrics_source"}
    )

    # Get the query execution ID
    query_execution_id = response['QueryExecutionId']
    
    # Wait for the query to complete
    while True:
        query_status = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
        status = query_status['QueryExecution']['Status']['State']
        
        if status == 'SUCCEEDED':
            print("Query succeeded!")
            break
        elif status in ['FAILED', 'CANCELLED']:
            print(f"Query {status.lower()}!")
            raise Exception(f"Query {status.lower()}: {query_status['QueryExecution']['Status']['StateChangeReason']}")
        else:
            print("Waiting for query to complete...")
            time.sleep(5)  # Wait for 5 seconds before checking again

    # Convert the SQL query output to filetype
    try:
        glue_response = glue_client.start_job_run(
            JobName=glue_job_name,
            Arguments={
                '--SOURCE_PATH': f"{output_location}/score_avg_metrics_source",
                '--TARGET_FORMAT': f'{filetype}',
                '--TARGET_S3_BUCKET': s3_bucket,
                '--TARGET_S3_PATH': f"{output_location}/score_avg_metrics"
            }
        )
        job_run_id = glue_response['JobRunId']
        print(f"Started Glue job: {glue_response['JobRunId']}")
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f"Error starting Glue job: {str(e)}"
        }

    # Wait for the Glue job to complete
    while True:
        job_status_response = glue_client.get_job_run(JobName=glue_job_name, RunId=job_run_id)
        job_status = job_status_response["JobRun"]["JobRunState"]

        if job_status == "SUCCEEDED":
            print("Glue job succeeded!")
            break
        elif job_status in ["FAILED", "STOPPED"]:
            print(f"Glue job {job_status.lower()}!")
            raise Exception(f"Glue job {job_status.lower()}: {job_status_response['JobRun']['ErrorMessage']}")
        else:
            print("Waiting for Glue job to complete...")
            time.sleep(10)  # Wait for 10 seconds before checking again

    # Start the crawler
    try:
        crawler_client.start_crawler(Name=crawler_avg_name)
        print(f"Crawler '{crawler_avg_name}' started successfully.")
    except crawler_client.exceptions.CrawlerRunningException:
        print(f"Crawler '{crawler_avg_name}' is already running.")
        return {
            'statusCode': 400,
            'body': f"Crawler '{crawler_avg_name}' is already running."
        }
    except Exception as e:
        print(f"Failed to start crawler '{crawler_avg_name}': {str(e)}")
        return {
            'statusCode': 500,
            'body': f"Failed to start crawler '{crawler_avg_name}': {str(e)}"
        }
    
    # Wait for the crawler to complete
    while True:
        response = crawler_client.get_crawler(Name=crawler_avg_name)
        crawler_state = response['Crawler']['State']
        
        if crawler_state == 'READY' or crawler_state == 'STOPPING':
            print(f"Crawler '{crawler_name}' completed successfully.")
            break
        elif crawler_state == 'RUNNING':
            print(f"Waiting for crawler '{crawler_avg_name}' to complete...")
            time.sleep(30)  # Wait for 30 seconds before checking again
        else:
            print(f"Crawler '{crawler_avg_name}' is in an unexpected state: {crawler_state}")
            return {
                'statusCode': 500,
                'body': f"Crawler '{crawler_avg_name}' failed or is in an unexpected state: {crawler_state}"
            }
    
    s3_source = boto3.client("s3", region_name='us-east-1')
    s3_destination = boto3.client("s3", region_name='us-west-1')

    source_bucket = os.environ['SOURCE_BUCKET'].lower()
    destination_bucket = os.environ['DESTINATION_BUCKET'].lower()


    folders = ['score_metrics_source', 'score_avg_metrics_source']
    
    try:
        for folder in folders:
            source_folder = f"{query_results_path}/{folder}"
            destination_folder = f"{query_results_path}/{folder}"

            logger.info(f"Processing folder: {folder}")

            response = s3_source.list_objects_v2(Bucket=source_bucket, Prefix=source_folder)
            
            if 'Contents' not in response:
                logger.error(f"No files found in the source path {source_folder}")
                continue

            for obj in response['Contents']:
                source_key = obj['Key']
                destination_key = source_key.replace(source_folder, destination_folder, 1)

                copy_source = {'Bucket': source_bucket, 'Key': source_key}

                s3_destination.copy_object(CopySource=copy_source, Bucket=destination_bucket, Key=destination_key)
                logger.info(f"Copied {source_key} to {destination_key}")

                s3_source.delete_object(Bucket=source_bucket, Key=source_key)
                logger.info(f"Deleted {source_key} from {source_bucket}")
        
        return {"statusCode": 200, "body": f"Files copied and deleted successfully from folders: {', '.join(folders)}"}
    
    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        return {"statusCode": 500, "body": str(e)}
