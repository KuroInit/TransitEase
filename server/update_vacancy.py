import requests
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv
from collections import defaultdict
import os
import pyproj
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

# Read from environment variables
ACCESS_KEY = os.getenv("URA_ACCESS_KEY")
TOKEN = os.getenv("URA_TOKEN")
FIREBASE_CREDENTIALS_JSON = os.getenv("FIREBASE_JSON")

# Initialize Firebase Admin SDK
cred = credentials.Certificate(FIREBASE_CREDENTIALS_JSON)
firebase_admin.initialize_app(cred)
db = firestore.client()  # Create a Firestore client

# Define SVY21 and WGS84 coordinate systems
svy21 = pyproj.Proj(
    "+proj=tmerc +lat_0=1.366666 +lon_0=103.833333 +k=1 +x_0=28001.642 +y_0=38744.572 +ellps=WGS84 +units=m +no_defs"
)
wgs84 = pyproj.Proj(proj="latlong", datum="WGS84")


def fetch_car_park_availability() -> dict:
    """Fetch car park availability data from the URA API."""
    url = "https://www.ura.gov.sg/uraDataService/invokeUraDS?service=Car_Park_Availability"
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
        logger.error(f"Error fetching car park availability data: {e}")
        return {}


def update_car_park_availability(data):
    """Update Firestore car park documents with availability data."""
    car_parks_ref = db.collection("car_parks")

    for car_park in data:
        pp_code = car_park.get("carparkNo")  # This is the ppCode or car park name
        lots_available = int(car_park.get("lotsAvailable", 0))  # Ensure it's an integer
        lot_type = car_park.get("lotType")

        if not pp_code:
            logger.warning("Missing carparkNo, skipping entry.")
            continue

        try:
            # Update the existing document in the 'car_parks' collection by ppCode
            car_park_doc_ref = car_parks_ref.document(pp_code)
            car_park_doc_ref.update(
                {
                    f"availability.{lot_type}": {
                        "lotsAvailable": lots_available,
                    }
                }
            )
            logger.info(
                f"Updated carparkNo {pp_code} with {lots_available} lots available for lot type {lot_type}."
            )
        except Exception as e:
            logger.error(f"Error updating carparkNo {pp_code}: {e}")


# Main function to execute the script
if __name__ == "__main__":
    try:
        # Fetch car park availability data from URA API
        availability_data = fetch_car_park_availability()
        print(availability_data)
        logger.info("Car park availability data fetched from URA API.")

        if "Result" in availability_data and isinstance(
            availability_data["Result"], list
        ):
            logger.info("Updating car park availability data in Firestore...")
            update_car_park_availability(availability_data["Result"])
            logger.info("Car park availability data updated successfully.")
        else:
            logger.warning("No car park availability data found in the response.")
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}")
