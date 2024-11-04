import requests
import os
from dotenv import load_dotenv
import logging

# Configure logging
logging.basicConfig(
    filename="/app/logs/renew_token.log",  # Log file location inside Docker container
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
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


def make_request():
    # Get the access key from the environment variable
    access_key = os.getenv("URA_ACCESS_KEY")

    if not access_key:
        logger.error("Access key not found in .env file.")
        return None

    url = "https://www.ura.gov.sg/uraDataService/insertNewToken.action"

    headers = {
        "User-Agent": "curl/8.7.1",
        "Accept": "*/*",
        "AccessKey": access_key,  # Use the access key from the .env file
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # Raise an exception for HTTP errors
        logger.info("Request successful with status code: %s", response.status_code)
        return response

    except requests.exceptions.RequestException as e:
        logger.error("An error occurred during the request: %s", e)
        return None


def write_to_env_file(token):
    try:
        # Read the .env file contents
        with open(dotenv_path, "r") as env_file:
            lines = env_file.readlines()

        # Write the updated token to the .env file
        with open(dotenv_path, "w") as env_file:
            for line in lines:
                if line.startswith("URA_TOKEN="):
                    env_file.write(f"URA_TOKEN={token}\n")  # Replace the existing token
                    logger.info("URA_TOKEN updated in .env file.")
                else:
                    env_file.write(line)  # Write other lines as they are

        logger.info(f".env file updated successfully at {os.path.abspath(dotenv_path)}")

    except Exception as e:
        logger.error(f"Error updating .env file: {e}")


if __name__ == "__main__":
    # Make the GET request
    response = make_request()
    if response:
        response_json = response.json()

        # Write the new token to the .env file
        if "Result" in response_json:
            write_to_env_file(response_json["Result"])
            logger.info("New token obtained and written to .env file.")
        else:
            logger.warning("No token found in the response.")
