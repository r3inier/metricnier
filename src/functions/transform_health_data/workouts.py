from helper import add_file_to_bucket, extract_date, extract_time

def transform_workouts(data):
    workouts = data["body"]["data"]["workouts"]
    workouts_by_day = {}
    for w in workouts:
        id = w["id"]
        name = w["name"]
        date = extract_date(w["start"])
        start_time = extract_time(w["start"])
        end_time = extract_time(w["end"])
        duration = {
            "qty": w["duration"],
            "units": "s"
        }
        w.pop("id")
        w.pop("name")
        w.pop("start")
        w.pop("end")
        w.pop("duration")

        transformed_workout = {
            "id": id,
            "name": name,
            "start_time": start_time,
            "end_time": end_time,
            "duration": duration
        }
    
        # Transforming times of heart rate data
        heart_rate_data = w["heartRateData"]
        new_heart_rate_data = {
            "data": [],
            "units": "bpm"
        }
        for hr in heart_rate_data:
            new_heart_rate_data["data"].append({
                "time": extract_time(hr["date"]), # extracting time as the directory is already structured by date
                "qty": hr["qty"]
            })
        transformed_workout["heartRateData"] = new_heart_rate_data
        w.pop("heartRateData")

        # Transforming times of heart rate recovery data
        heart_rate_recovery_data = w["heartRateRecovery"]
        new_heart_rate_recovery_data = {
            "data": [],
            "units": "bpm"
        }
        for hr in heart_rate_recovery_data:
            new_heart_rate_recovery_data["data"].append({
                "time": extract_time(hr["date"]), # extracting time as the directory is already structured by date
                "qty": hr["qty"]
            })
        transformed_workout["heartRateRecoveryData"] = new_heart_rate_recovery_data
        w.pop("heartRateRecovery")

        transformed_workout = transformed_workout | w

        if date not in workouts_by_day:
            workouts_by_day[date] = []
        
        workouts_by_day[date].append(transformed_workout)
    
    workouts_file_path = "processed/health/workouts/"
    for date in list(workouts_by_day.keys()):
        dated_file_path = workouts_file_path + date + ".json"
        add_file_to_bucket(dated_file_path, workouts_by_day[date])
