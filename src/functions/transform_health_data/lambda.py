import json
import boto3
import re

def add_file_to_bucket(file_path, data):
    s3 = boto3.client('s3')
    s3.put_object(
        Bucket="metricnier-bucket",
        Body=(bytes(json.dumps(data).encode('UTF-8'))), 
        Key=file_path
    )

def extract_date(timestamp):
    pattern = r"(\d{4})-(\d{2})-(\d{2})"
    match = re.search(pattern, timestamp)

    if match:
        year, month, day = match.groups()
        date = day + "-" + month + "-" + year
        return date
    else:
        return ""

def extract_time(timestamp):
    pattern = r"(\d{2}:\d{2}:\d{2,})"
    match = re.search(pattern, timestamp)

    if match:
        time = match.groups()
        return time[0]
    else:
        return ""


def transform_data(automation_name, data):
    if automation_name == "health-metrics":
        metrics = data["body"]["data"]["metrics"]
        for m in metrics:
            metric_name = m["name"]
            units = m["units"]
            metric_file_path = "processed/health/" + metric_name + "/"

            # Add metadata file for metric
            metadata_file_path = metric_file_path + "metadata.json"
            metadata = {
                "units": units
            }
            add_file_to_bucket(metadata_file_path, metadata)

            # Re-formatting metric data split by date
            curr_metric_data = []
            prev_date = ""
            metric_data = m["data"]

            for d in metric_data:
                timestamp = d["date"]
                d.pop("date")
                time = extract_time(timestamp)
                curr_date = extract_date(timestamp)

                if prev_date != "" and curr_date != "" and prev_date != curr_date:
                    dated_metric_file_path = metric_file_path + prev_date + ".json"
                    add_file_to_bucket(dated_metric_file_path, curr_metric_data)
                    curr_metric_data = []

                if "source" in d:
                    d.pop("source")

                # Creating 
                data_to_append = {
                    "time": time
                }
                data_to_append = data_to_append | d

                curr_metric_data.append(data_to_append)

                prev_date = curr_date

            # Adding data for current date
            if curr_metric_data:
                dated_metric_file_path = metric_file_path + prev_date + ".json"
                add_file_to_bucket(dated_metric_file_path, curr_metric_data)

    if automation_name == "workouts":
        print("lol")

def lambda_handler(event, context):
    bucket_name = "metricnier-bucket"
    input_file = event["Records"][0]["s3"]["object"]["key"]
    output_file = ""
    automation_name = input_file.replace("raw/health/", "").replace(".json", "")

    if automation_name == "health-metrics":
        output_file = "processed/health/health-metrics.json"
    elif automation_name == "workouts":
        output_file = "processed/health/workouts.json"
    else:
        return {
            'statusCode': 422,
            'body': 'Invalid automation name: ' + automation_name
        }
    
    s3 = boto3.client('s3')
    s3_object = s3.get_object(
        Bucket=bucket_name, 
        Key=input_file
    )
    data = json.loads(s3_object['Body'].read().decode('UTF-8'))
    add_file_to_bucket(output_file, data) # remove when done testing
    transform_data(automation_name, data) 

    return {
       'statusCode' : 200,
       'body': 'Data uploaded successfully'
   }

