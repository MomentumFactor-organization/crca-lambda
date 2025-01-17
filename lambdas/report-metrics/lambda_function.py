import json
import boto3 
import botocore
import requests as rq
import os 
import pandas as pd
from time import sleep
from metrics_calculations import aggregate_data, calculate_metrics

# USER_METRICS_BUCKET = os.getenv("USER_METRICS_BUCKET")
# ATHENA_RESULTS_BUCKET = os.getenv("ATHENA_RESULTS_BUCKET")


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


METRICS_BUCKET = os.getenv("METRICS_BUCKET")

API_URL =  os.getenv("API_URL")
ATHENA_TABLE = os.getenv("ATHENA_TABLE")
ATHENA_DB = os.getenv("ATHENA_DB")


def lambda_handler(event, context):
    secrets = get_secret()
    
    API_USER = secrets["API_USER"]
    API_PASSWORD = secrets["API_PASSWORD"]
    user_data = json.loads(event["Records"][0]["body"])
    username = user_data["username"]
    platform = user_data["platform"]
    
    athena = boto3.client("athena",region_name="us-east-1")
    s3 = boto3.client("s3")
    
    metrics_list = {}
    platforms = {}
    with open("metrics_list.json","r") as metrics_lists_files: 
        metrics_list = json.loads(metrics_lists_files.read())
    with open("platform.json","r") as platforms_files: 
        platforms = json.loads(platforms_files.read())
    post_metrics = {}
    report_metrics = {}
    try:
        print("Retrieving data from athena")
        athena_results_path = f'query_results'
        athena_results_output = f"s3://{METRICS_BUCKET}/{athena_results_path}"
        post_metrics_data = {}
        
        query_exec_id = athena.start_query_execution(
            QueryString=f"select * from {ATHENA_DB}.{ATHENA_TABLE} where username = '{username}' and platform = '{platform}'",\
            QueryExecutionContext={'Database': ATHENA_DB},\
            ResultConfiguration={'OutputLocation': athena_results_output})
        print("Sent to athena")
        wait_job = True
        while wait_job:
            print("checking status")
            sleep(2)
            status = athena.get_query_execution(QueryExecutionId=query_exec_id["QueryExecutionId"])
            print("current status:", status)
            if status['QueryExecution']["Status"]["State"] == "SUCCEEDED":
                print(status)
                sleep(5)
                print(f"s3 path {athena_results_path}/{query_exec_id["QueryExecutionId"]}.csv")
                post_metrics_data = pd.read_csv(s3.get_object(Bucket=METRICS_BUCKET, Key=f"{athena_results_path}/{query_exec_id["QueryExecutionId"]}.csv")['Body']).to_dict(orient="Records")
                wait_job = False
            if status['QueryExecution']["Status"]["State"] == "FAILED":
                raise Exception("Error in query execution")
        print("Calculating metrics",f"reportmetrics/platform={platform}/username={username}/data.json")
        post_metrics = aggregate_data(post_metrics_data)
        report_metrics_data = json.loads(s3.get_object(Bucket=METRICS_BUCKET, Key=f"reportmetrics/platform={platform}/username={username}/data.json")['Body'].read().decode('utf-8'))
        print("Creating metrics report")
        for metric_name in metrics_list["raw_metrics"]:
            report_metrics[metric_name] = report_metrics_data[metric_name] if report_metrics_data[metric_name] is None else 0
    except botocore.exceptions.ClientError as e:
        print(e)
        return {
        'statusCode': 400,
        'body': json.dumps('Problems with metrics files')
        }
    
    result_metrics = calculate_metrics(report_metrics,post_metrics)
    api_payload = []
    auth_payload = {'email': API_USER,'password': API_PASSWORD}
    auth_response = rq.post( f"{API_URL}/api/token/", data=json.dumps(auth_payload),headers={'Content-Type': 'application/json'})
    print(auth_response)
    
    for key in result_metrics.keys(): 
        api_payload.append({"Username":username,"Platform":platforms[platform],"Field":key, "Value":result_metrics[key]})
   
    json_payload = data=json.dumps(api_payload)
    print(json_payload)
    
    api_token = json.loads(auth_response.content)["access"]
    response = rq.post(API_URL+"/api/registry/metrics/",data=json.dumps(api_payload),headers={'Content-Type': 'application/json',"Authorization":f"Bearer {api_token}"})
    print(response.content)
    
    return {
        'statusCode': 200,
        'body': response.content
    }
