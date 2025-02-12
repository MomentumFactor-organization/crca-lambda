import boto3
import httpx
import json
import os
import base64
from decimal import Decimal
from botocore.exceptions import ClientError

# AWS configuration and secrets
dynamodb = boto3.resource('dynamodb')
secretsmanager = boto3.client('secretsmanager')
sns = boto3.client('sns')

# Load secrets from AWS Secrets Manager
def load_secrets():
    secret_name = os.getenv("INSIGHTIQ_SECRET_NAME")

    if not secret_name:
        raise ValueError("INSIGHTIQ_SECRET_NAME environment variable is not set")

    try:
        response = secretsmanager.get_secret_value(SecretId=secret_name)
        secrets = json.loads(response['SecretString'])
        return secrets
    except ClientError as e:
        print(f"Error fetching secrets: {e.response['Error']['Message']}")
        raise e

# Load secrets and configure environment variables
secrets = load_secrets()
TABLE_NAME = os.getenv("DYNAMODB_TABLE_NAME")
INSIGHTIQ_PASSWORD = secrets['INSIGHTIQ_PASSWORD']
INSIGHTIQ_USER = secrets['INSIGHTIQ_USER']
INSIGHTIQ_API_URL = secrets['INSIGHTIQ_API_URL']
DJANGO_WEBHOOK_URL = os.getenv("DJANGO_WEBHOOK_URL")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN")
DYNAMO_TABLE = dynamodb.Table(TABLE_NAME)

# Construct Basic authentication header
credentials = f"{INSIGHTIQ_USER}:{INSIGHTIQ_PASSWORD}"
encoded_credentials = base64.b64encode(credentials.encode('utf-8')).decode('utf-8')
HEADERS = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': f'Basic {encoded_credentials}'
}

def add_metrics(result, match_value=None):
    """
    Adds a default metrics list to the result dictionary and populates
    the metrics for 'reach', 'match', and 'safety' accordingly.
    """
    # Define the default metrics structure
    metrics = [
        {
            'gradient': None,  # Will be computed for 'reach'
            'gradient_init': None,
            'units': '%',
            'name': 'reach',
            'label': 'Reach',
            'description': 'Audience engagement reach',
            'value': 0.0,
        },
        {
            'gradient': None,  # Will be computed for 'match' if provided
            'gradient_init': None,
            'units': '%',
            'name': 'match',
            'label': 'Match',
            'description': 'Match percentage with target audience',
            'value': 0.0,
        },
        {
            'gradient': None,  # Dummy values for 'safety'
            'gradient_init': None,
            'units': '-',
            'name': 'safety',
            'label': 'Safety',
            'description': 'Social channel safety',
            'value': 0.0,
        }
    ]

    # Process 'reach' metric using engagement_rate from result.profile
    profile = result.get('profile', {})
    engagement_rate = 0

    # Check if profile is a dict or a list
    if isinstance(profile, dict):
        engagement_rate = profile.get('engagement_rate', 0) or 0
    elif isinstance(profile, list) and len(profile) > 0:
        engagement_rate = profile[0].get('engagement_rate', 0) or 0

    reach_value = round(engagement_rate * 100, 2)
    deflection_percentage = (
        0.0 if engagement_rate <= 0.001 else
        0.25 if engagement_rate <= 0.01 else
        0.50 if engagement_rate <= 0.035 else
        0.75 if engagement_rate <= 0.045 else
        1.0
    )

    # Update the metrics list with computed values
    for metric in metrics:
        if metric['name'] == 'reach':
            metric['value'] = reach_value
            metric['gradient_init'] = round(deflection_percentage, 2)
            metric['gradient'] = round(deflection_percentage * 100, 2)
        elif metric['name'] == 'match':
            # Process the 'match' metric if a valid match_value is provided
            if match_value is not None:
                # If match_value is a string, remove any extra whitespace
                if isinstance(match_value, str):
                    match_value = match_value.strip()
                try:
                    match_numeric = float(match_value)
                    # Ensure the value is between 0 and 100
                    if 0 <= match_numeric <= 100:
                        match_numeric = round(match_numeric, 2)
                        metric['value'] = match_numeric
                        metric['gradient'] = round(match_numeric, 2)
                        metric['gradient_init'] = round(match_numeric / 100, 4)
                except (ValueError, TypeError) as err:
                    # Log the error for debugging purposes
                    print(f"Error converting match_value: {err}")
        elif metric['name'] == 'safety':
            # Dummy assignment for 'safety'
            metric['value'] = None
            metric['gradient'] = None
            metric['gradient_init'] = None

    # Add the metrics list to the result object
    result['metrics'] = metrics
    return result

def lambda_handler(event, context):
    """
    Entry point for the Lambda function.
    Handles HTTP requests routed through API Gateway.
    """
    try:
        http_method = event.get("httpMethod", "")
        path = event.get("path", "")

        if http_method == "POST" and path.endswith("/initiate"):
            return handle_post_request(event)
        else:
            return {
                "statusCode": 405,
                "body": json.dumps({"error": "Method Not Allowed"})
            }
    except Exception as e:
        print(f"Error in lambda_handler: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

def handle_post_request(event):
    """Initiates a request to InsightIQ based on the platform."""
    try:
        data = json.loads(event['body'])
        identifier = data.get('identifier')
        work_platform_id = data.get('work_platform_id')
        # Get optional 'match' parameter from POST data
        match_value = data.get('match', None)

        # Log received match_value for debugging
        print(f"Received match_value: {match_value} (type: {type(match_value)})")

        if not identifier or not work_platform_id:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing required fields: identifier or work_platform_id"})
            }

        # List of platforms that require a synchronous request
        sync_platforms = [
            "de55aeec-0dc8-4119-bf90-16b3d1f0c987",  # TikTok
            "9bb8913b-ddd9-430b-a66a-d74d846e6c66",  # Instagram
            "14d9ddf5-51c6-415e-bde6-f8ed36ad7054",  # YouTube
        ]

        # Validate work_platform_id
        if work_platform_id not in sync_platforms:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Invalid work_platform_id. Please provide a valid platform ID."})
            }

        # Call the synchronous request handler and pass match_value
        return handle_sync_request(identifier, work_platform_id, match_value)

    except Exception as e:
        print(f"Error in handle_post_request: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

def handle_sync_request(identifier, work_platform_id, match_value=None):
    """Handles synchronous requests to InsightIQ."""
    try:
        payload = {"identifier": identifier, "work_platform_id": work_platform_id}
        url = f"{INSIGHTIQ_API_URL}social/creators/profiles/analytics"

        with httpx.Client(timeout=60) as client:
            response = client.post(url, json=payload, headers=HEADERS)

            if response.status_code == 400:
                error_data = response.json()
                if error_data.get("error", {}).get("code") == "retry_later":
                    return {
                        "statusCode": 202,
                        "body": json.dumps({
                            "message": "Data is being updated. Please retry later. (20min approx)"
                        })
                    }

            if response.status_code != 200:
                return {
                    "statusCode": response.status_code,
                    "body": json.dumps({"error": "An error occurred with the data provider."})
                }

            result = response.json()

            # Add metrics to the result object before storing in DynamoDB
            result = add_metrics(result, match_value)

            # Convert floats to Decimal before storing in DynamoDB
            result = convert_to_decimal(result)

            # Store result in DynamoDB
            DYNAMO_TABLE.put_item(
                Item={
                    "work_platform_id": work_platform_id,
                    "identifier": identifier,
                    "status": "SUCCESS",
                    "result": result,
                }
            )

            # Convert result to JSON serializable before returning
            serializable_result = convert_to_serializable(result)

            return {"statusCode": 200, "body": json.dumps(serializable_result)}

    except Exception as e:
        print(f"Error in handle_sync_request: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

def convert_to_decimal(data):
    """
    Recursively convert floats to Decimals in a dictionary or list.
    """
    if isinstance(data, list):
        return [convert_to_decimal(item) for item in data]
    elif isinstance(data, dict):
        return {key: convert_to_decimal(value) for key, value in data.items()}
    elif isinstance(data, float):
        return Decimal(str(data))
    return data

def convert_to_serializable(data):
    """
    Recursively convert Decimals to floats in a dictionary or list to make them JSON serializable.
    """
    if isinstance(data, list):
        return [convert_to_serializable(item) for item in data]
    elif isinstance(data, dict):
        return {key: convert_to_serializable(value) for key, value in data.items()}
    elif isinstance(data, Decimal):
        return float(data)  # Convert Decimal to float for JSON serialization
    return data

def handle_async_request(identifier, work_platform_id, update_existing, match_value=None):
    """Handles asynchronous requests to InsightIQ."""
    try:
        payload = {"identifier": identifier, "work_platform_id": work_platform_id}
        url = f"{INSIGHTIQ_API_URL}social/creators/async/profiles/analytics"

        with httpx.Client(timeout=60) as client:
            response = client.post(url, json=payload, headers=HEADERS)

            if response.status_code != 200:
                return {
                    "statusCode": response.status_code,
                    "body": response.text
                }

            result = response.json()

            if "id" not in result or "status" not in result:
                return {
                    "statusCode": 500,
                    "body": json.dumps({"error": "Invalid response from InsightIQ"})
                }

            # Add metrics to the result object before storing in DynamoDB
            result = add_metrics(result, match_value)

            # Convert floats to Decimal before storing in DynamoDB
            result = convert_to_decimal(result)

            # Store result in DynamoDB
            DYNAMO_TABLE.put_item(
                Item={
                    "work_platform_id": work_platform_id,
                    "identifier": identifier,
                    "id": result["id"],
                    "status": result["status"],
                    "result": result,
                }
            )

            # Convert result to JSON serializable before returning
            serializable_result = convert_to_serializable(result)

            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=json.dumps(serializable_result),
                Subject="InsightIQ Report Update",
            )

            return {"statusCode": 201, "body": json.dumps(serializable_result)}

    except Exception as e:
        print(f"Error in handle_async_request: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

def handle_webhook(event):
    """Handles status updates from InsightIQ"""
    try:
        data = json.loads(event['body'])
        insight_id = data.get('id')
        status = data.get('status')

        if not insight_id or not status:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Missing required fields: id or status"})
            }

        # Update DynamoDB
        DYNAMO_TABLE.update_item(
            Key={'id': insight_id},
            UpdateExpression="SET #st = :s",
            ExpressionAttributeNames={"#st": "status"},
            ExpressionAttributeValues={":s": status}
        )

        # Fetch final results if status is SUCCESS
        if status == "SUCCESS":
            fetch_final_results(insight_id)

        return {"statusCode": 200, "body": "Webhook processed successfully"}

    except Exception as e:
        print(f"Error in handle_webhook: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}

def fetch_final_results(insight_id):
    """Fetches final results from InsightIQ"""
    try:
        url = f"{INSIGHTIQ_API_URL}social/creators/async/profiles/analytics/{insight_id}"

        with httpx.Client(timeout=60) as client:
            response = client.get(url, headers=HEADERS)
            result = response.json()

            # Update DynamoDB
            DYNAMO_TABLE.update_item(
                Key={"id": insight_id},
                UpdateExpression="SET #res = :r, #st = :s",
                ExpressionAttributeNames={"#res": "result", "#st": "status"},
                ExpressionAttributeValues={":r": result, ":s": "SUCCESS"}
            )

            # Notify Django
            notify_django(result)

    except Exception as e:
        print(f"Error in fetch_final_results: {e}")

def notify_django(result):
    """Notifies Django with final results"""
    try:
        with httpx.Client(timeout=60) as client:
            client.post(DJANGO_WEBHOOK_URL, json=result)
    except Exception as e:
        print(f"Error notifying Django: {e}")
