import json
import requests as rq
import os
import boto3
from io import BytesIO

SCRAPER_SQS = os.getenv("SCRAPER_SQS")
API_URL = os.getenv("API_URL")
API_USER = os.getenv("API_USER")
API_PASSWORD = os.getenv("API_PASSWORD")

ATHENA_RESULTS_BUCKET = os.getenv("ATHENA_RESULTS_BUCKET")
ATHENA_DB = os.getenv("ATHENA_DB")
ATHENA_METRICS_TABLE = os.getenv("ATHENA_METRICS_TABLE")

USER_METRICS_BUCKET = os.getenv("USER_METRICS_BUCKET")

platforms = {"tiktok":1,"instagram":2,"youtube":3,"facebook":4,"x":5}

def lambda_handler(event, context):
    sqs = boto3.client("sqs")
    athena = boto3.client("athena",region_name="us-east-1")
    
    result_creators = []
    result_query =f"ALTER TABLE {ATHENA_METRICS_TABLE} ADD IF NOT EXISTS  "
    sub_query = ""
    print()
    for record in event["Records"]:
        creator = json.loads(record["body"])
        
        platform = creator["work_platform"]["name"].lower()
        creator_data = {"username":creator["platform_username"],"platform":platform}
        sqs.send_message(QueueUrl=SCRAPER_SQS,
        MessageBody=json.dumps({"records":[creator_data]} ) )
        platform_id = platforms[platform]
        result_creators.append({"Username":creator_data["username"],"Platform":platform_id,"ProfileURL":creator["url"]})
        extract_creators_metrics(creator,platform,creator_data["username"])
        athena_results_path = f'partition_results'
        athena_results_output = f"s3://{ATHENA_RESULTS_BUCKET}/{athena_results_path}"
        print(f"Adding partitions: {creator_data['username']}@{creator_data['platform']}")
        sub_query =f"{sub_query} PARTITION (platform='{creator_data['platform']}',username='{creator_data['username']}' )"
    
    print(f"{result_query} {sub_query}")
    query_exec_id = athena.start_query_execution(
        QueryString=f"{result_query} {sub_query}",\
        QueryExecutionContext={'Database': ATHENA_DB},\
        ResultConfiguration={'OutputLocation': athena_results_output})
    # payload = {'email': API_USER,'password': API_PASSWORD}
    # print("Authenticating to API")
    # auth_response = rq.post( f"{API_URL}/api/token/", data=json.dumps(payload),headers={'Content-Type': 'application/json'})
    # print(auth_response)
    # api_token = json.loads(auth_response.content)["access"]
    # print("Sending Creators")
    # try:
        # response = rq.post(f"{API_URL}/api/registry/platformuser/",data=json.dumps(result_creators),
        #                         headers={'Content-Type': 'application/json',"Authorization":f"Bearer {api_token}"},
        #                         timeout=10)
        # print(response.content)
    # except rq.Timeout as e:
    #     print("Error sending creators")
    #     print(response.content)
    return {
        'statusCode': 200,
        'body': json.dumps('Report processed')
    }

def extract_creators_metrics(creator_data,platform,username):
    report_metrics_fieldnames = []
    report_metrics = {}
    metrics_tags_filename = "report_fields.json"
    with open(metrics_tags_filename,"r") as reports_fields_file:
        report_metrics_fieldnames = json.load(reports_fields_file)["report_metrics"]
    for metric in report_metrics_fieldnames:
        report_metrics[metric] = creator_data[metric]
    s3 = boto3.client("s3")
    s3.upload_fileobj(
            BytesIO(json.dumps(report_metrics).encode()),
            USER_METRICS_BUCKET,
            f"reportmetrics/platform={platform}/username={username}/data.json"
    )