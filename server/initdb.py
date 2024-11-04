import requests
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
from collections import defaultdict
import os
import pyproj
import logging
import geohash2  # Import the geohash library

# Configure logging
logging.basicConfig(
    filename="/app/logs/initdb.log",  # Log file location inside the Docker container
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

dotenv_path = "/app/.env"
# Load environment variables from .env file
try:
    # Attempt to load .env file from the specified path
    if load_dotenv(dotenv_path):
        logger.info(f".env file loaded successfully from {dotenv_path}")
    else:
        # If load_dotenv returns False, the file was not found or could not be loaded
        logger.warning(f".env file not found or could not be loaded from {dotenv_path}")
except Exception as e:
    # Log any unexpected errors during the load attempt
    logger.error(f"Error loading .env file from {dotenv_path}: {e}")

# Read from environment variables
ACCESS_KEY = os.getenv("URA_ACCESS_KEY")
TOKEN = os.getenv("URA_TOKEN")
FIREBASE_CREDENTIALS_JSON = os.getenv("FIREBASE_JSON")

# Initialize Firebase Admin SDK
cred = credentials.Certificate(FIREBASE_CREDENTIALS_JSON)
firebase_admin.initialize_app(cred)
db = firestore.client()  # Create a Firestore client

# List of ppCodes to exclude
EXCLUDED_PPCODES = ["K0025"]

# Define SVY21 and WGS84 coordinate systems
svy21 = pyproj.Proj(
    "+proj=tmerc +lat_0=1.366666 +lon_0=103.833333 +k=1 +x_0=28001.642 +y_0=38744.572 +ellps=WGS84 +units=m +no_defs"
)
wgs84 = pyproj.Proj(proj="latlong", datum="WGS84")


def fetch_ura_data() -> dict:
    """Fetch data from the URA API."""
    url = "https://www.ura.gov.sg/uraDataService/invokeUraDS?service=Car_Park_Details"
    headers = {
        "User-Agent": "curl/8.7.1",
        "Accept": "*/*",
        "AccessKey": ACCESS_KEY,
        "Token": TOKEN,
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # Raise an error for bad responses
        return response.json()
    except requests.RequestException as e:
        logger.error(f"Error fetching URA data: {e}")
        return {}


def convert_svy21_to_wgs84(svy21_coordinates: list) -> tuple:
    """Convert SVY21 coordinates to WGS84."""
    if len(svy21_coordinates) != 2:
        logger.warning(f"Invalid SVY21 coordinates: {svy21_coordinates}")
        return None, None

    easting, northing = svy21_coordinates
    lon, lat = pyproj.transform(svy21, wgs84, easting, northing)
    return lon, lat


def group_data_by_pp_code(data):
    grouped_data = defaultdict(
        lambda: {
            "ppCode": None,
            "ppName": None,
            "parkingSystem": None,
            "geometries": None,
            "geohash": None,  # Add geohash field
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

            # Convert SVY21 coordinates to WGS84
            svy21_coordinates = car_park["geometries"][0]["coordinates"]
            if svy21_coordinates and isinstance(svy21_coordinates, str):
                try:
                    easting_str, northing_str = svy21_coordinates.split(",")
                    easting = float(easting_str)
                    northing = float(northing_str)
                except ValueError:
                    print(
                        f"Error converting coordinates for ppCode {pp_code}: {svy21_coordinates}"
                    )
                    continue

                # Perform the transformation
                lon, lat = pyproj.transform(svy21, wgs84, easting, northing)
                grouped_data[pp_code]["geometries"] = {
                    "coordinates": [lon, lat]  # Store as [longitude, latitude]
                }

                # Compute the geohash and add to the grouped data
                geo_hash = geohash2.encode(lat, lon)
                grouped_data[pp_code]["geohash"] = geo_hash  # Add the geohash

            else:
                print(f"Invalid coordinates format for ppCode {pp_code}.")
                continue

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


def push_grouped_data_to_firestore(grouped_data: dict):
    """Push grouped data to Firestore."""
    car_parks_ref = db.collection("car_parks")
    total_documents = 0  # Counter for the total number of documents

    for pp_code, car_park_data in grouped_data.items():
        try:
            car_parks_ref.document(pp_code).set({"carpark": car_park_data})
            total_documents += 1  # Increment the document count
            logger.info(f"Successfully pushed data for ppCode: {pp_code}")
        except Exception as e:
            logger.error(f"Error pushing data for ppCode {pp_code}: {e}")

    # Log the total number of documents pushed to Firestore
    logger.info(f"Total documents pushed to Firestore: {total_documents}")


# Main function to execute the script
if __name__ == "__main__":
    try:
        # Fetch data from URA API
        ura_data = fetch_ura_data()
        logger.info("Data fetched from URA API.")

        if "Result" in ura_data and isinstance(ura_data["Result"], list):
            logger.info("Grouping and pushing data to Firestore...")
            grouped_data = group_data_by_pp_code(ura_data["Result"])
            push_grouped_data_to_firestore(grouped_data)
            logger.info("Data pushed to Firestore successfully.")
        else:
            logger.warning("No car park data found in the response.")
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}")
