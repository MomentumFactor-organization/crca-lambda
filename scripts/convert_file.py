import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

import boto3

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'SOURCE_PATH', 'TARGET_FORMAT', 'TARGET_S3_BUCKET', 'TARGET_S3_PATH'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Initialize S3 client
s3 = boto3.client('s3')

# Parse bucket name and prefix from SOURCE_PATH
source_bucket = args['SOURCE_PATH'].split('/', 3)[2]
source_prefix = args['SOURCE_PATH'].split('/', 3)[3]

# List all files in the source path
response = s3.list_objects_v2(Bucket=source_bucket, Prefix=source_prefix)
files = [content['Key'] for content in response.get('Contents', [])]

# Filter to only include CSV files
csv_files = [f"s3://{args['TARGET_S3_BUCKET']}/{file}" for file in files if isinstance(file, str) and file.endswith('.csv')]

if not csv_files:
    raise Exception("No CSV files found in the source path.")

# Load the data from S3
datasource0 = glueContext.create_dynamic_frame.from_options(
    "s3",
    {'paths': csv_files},
    format="csv",
    format_options={"withHeader": True}
)

if args['TARGET_FORMAT'].lower() == 'parquet':
    format_options = {"compression": "snappy"}
elif args['TARGET_FORMAT'].lower() == 'avro':
    format_options = {}
else:
    raise ValueError("Unsupported target format: " + args['TARGET_FORMAT'])


# Write the data back to S3 in the new format
print("Starting data write operation to S3...")
glueContext.write_dynamic_frame.from_options(
    frame=datasource0,
    connection_type="s3",
    connection_options={"path": args['TARGET_S3_PATH']},
    format=args['TARGET_FORMAT'],
    format_options=format_options
)
print("Data write operation completed.")

job.commit()
