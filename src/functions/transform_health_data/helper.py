import json
import boto3
import re

bucket_name = "metricnier-bucket"

def add_file_to_bucket(file_path, data):
    s3 = boto3.client('s3')
    s3.put_object(
        Bucket=bucket_name,
        Body=(bytes(json.dumps(data).encode('UTF-8'))), 
        Key=file_path
    )

def load_file_from_bucket(file_path):
    s3 = boto3.client('s3')
    s3_object = s3.get_object(
        Bucket=bucket_name, 
        Key=file_path
    )
    return json.loads(s3_object['Body'].read().decode('UTF-8'))

def extract_date(timestamp):
    pattern = r"(\d{4})-(\d{2})-(\d{2})"
    match = re.search(pattern, timestamp)

    if match:
        year, month, day = match.groups()
        date = day + "-" + month + "-" + year
        return date
    else:
        return "NA"

def extract_time(timestamp):
    pattern = r"(\d{2}:\d{2}:\d{2,})"
    match = re.search(pattern, timestamp)

    if match:
        time = match.groups()
        return time[0]
    else:
        return "NA"