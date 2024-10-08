import requests
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
from collections import defaultdict
import os

# Load environment variables from .env file
load_dotenv()

# Read from environment variables
ACCESS_KEY = os.getenv("URA_ACCESS_KEY")  # Access key from .env
TOKEN = os.getenv("URA_TOKEN")  # Token from .env
FIREBASE_CREDENTIALS_JSON = os.getenv("FIREBASE_JSON")  # Path to Firebase credentials

# Initialize Firebase Admin SDK
cred = credentials.Certificate(FIREBASE_CREDENTIALS_JSON)
firebase_admin.initialize_app(cred)
# Initialize Firestore
db = firestore.client()  # Create a Firestore client

# List of ppCodes to exclude
EXCLUDED_PPCODES = ["K0025"]


def fetch_ura_data():
    url = "https://www.ura.gov.sg/uraDataService/invokeUraDS?service=Car_Park_Details"
    headers = {
        "User-Agent": "curl/8.7.1",
        "Accept": "*/*",
        "AccessKey": ACCESS_KEY,
        "Token": TOKEN,
    }

    response = requests.get(url, headers=headers)
    response.raise_for_status()  # Raise an error for bad responses
    return response.json()  # Return the JSON response


def group_data_by_pp_code(data):
    grouped_data = defaultdict(
        lambda: {
            "ppCode": None,
            "ppName": None,
            "parkingSystem": None,
            "geometries": None,
            "vehCat": defaultdict(
                lambda: {
                    "parkCapacity": None,  # Store parkCapacity under each vehCat
                    "timeSlots": [],  # Store time slots for each vehCat
                }
            ),
        }
    )

    # Group the data by ppCode and organize by vehCat with time slots
    for car_park in data:
        pp_code = car_park["ppCode"]

        # Exclude specific ppCodes from being processed
        if pp_code in EXCLUDED_PPCODES:
            print(f"Excluding ppCode: {pp_code}")
            continue

        # Check if geometries exist and are valid
        if "geometries" not in car_park or not car_park["geometries"]:
            print(f"Skipping ppCode {pp_code} due to missing or invalid geometries.")
            continue

        veh_cat = car_park.get("vehCat")

        # If this is the first time we're seeing this ppCode, populate static fields
        if grouped_data[pp_code]["ppCode"] is None:
            grouped_data[pp_code]["ppCode"] = car_park.get("ppCode")
            grouped_data[pp_code]["ppName"] = car_park.get("ppName").strip()
            grouped_data[pp_code]["parkingSystem"] = car_park.get("parkingSystem")
            grouped_data[pp_code]["geometries"] = {
                "coordinates": car_park["geometries"][0]["coordinates"]
            }

        # Set parkCapacity for the vehicle category (it might be updated for each vehCat)
        grouped_data[pp_code]["vehCat"][veh_cat]["parkCapacity"] = car_park.get(
            "parkCapacity"
        )

        # Append the time slot information for each vehicle category
        grouped_data[pp_code]["vehCat"][veh_cat]["timeSlots"].append(
            {
                "startTime": car_park.get("startTime"),
                "endTime": car_park.get("endTime"),
                "weekdayRate": car_park.get("weekdayRate"),
                "satdayRate": car_park.get("satdayRate"),
                "sunPHRate": car_park.get("sunPHRate"),
                "weekdayMin": car_park.get("weekdayMin"),
                "satdayMin": car_park.get("satdayMin"),
                "sunPHMin": car_park.get("sunPHMin"),
            }
        )

    return grouped_data


# Function to push grouped data to Firestore
def push_grouped_data_to_firestore(grouped_data):
    # Reference to the Firestore collection
    car_parks_ref = db.collection("car_parks")

    # Iterate over each ppCode group and push to Firestore
    for pp_code, car_park_data in grouped_data.items():
        car_parks_ref.document(pp_code).set({"carpark": car_park_data})


# Main function to execute the script
if __name__ == "__main__":
    try:
        # Fetch data from URA API
        ura_data = fetch_ura_data()
        print(ura_data)

        # Check if the response has a 'Result' key
        if "Result" in ura_data and isinstance(ura_data["Result"], list):
            print("Data fetched successfully. Grouping and pushing to Firestore...")

            # Group the data by ppCode
            grouped_data = group_data_by_pp_code(ura_data["Result"])

            # Push the grouped data to Firestore
            push_grouped_data_to_firestore(grouped_data)

            print("Data pushed to Firestore successfully.")
        else:
            print("No car park data found in the response.")

    except Exception as e:
        print(f"An error occurred: {e}")
