from helper import add_file_to_bucket, extract_date, extract_time

def transform_health_metrics(data):
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