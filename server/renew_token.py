import requests
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


def make_request():
    # Get the access key from the environment variable
    access_key = os.getenv("URA_ACCESS_KEY")

    if not access_key:
        print("Error: Access key not found in .env file.")
        return

    url = "https://www.ura.gov.sg/uraDataService/insertNewToken.action"

    headers = {
        "User-Agent": "curl/8.7.1",
        "Accept": "*/*",
        "AccessKey": access_key,  # Use the access key from the .env file
    }

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # Raise an exception for HTTP errors

        print("Response Status Code:", response.status_code)
        return response

    except requests.exceptions.RequestException as e:
        print("An error occurred:", e)


def write_to_env_file(token):
    env_file_path = ".env"

    # Access the .env file exclusively and then close it after updating
    with open(env_file_path, "r") as env_file:
        lines = env_file.readlines()

    with open(env_file_path, "w") as env_file:
        for line in lines:
            if line.startswith("URA_TOKEN="):
                env_file.write(f"URA_TOKEN={token}\n")  # Replace the existing token
            else:
                env_file.write(line)  # Write other lines as they are

    print(f".env file updated at {os.path.abspath(env_file_path)}")


if __name__ == "__main__":
    # Make the GET request
    response = make_request()
    if response:
        response_json = response.json()

        # Write the new token to the .env file
        write_to_env_file(response_json["Result"])
