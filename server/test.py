import requests

# Replace these with your actual AccessKey and Token
access_key = "918a9a45-0cf9-4137-8a9a-587a50702d6e"
token = "P9-aMFh78@Jc1faaADvWM8Et6Z7042e3sPG19ar44T7Yuf3t8ag9sufUgB61X1aQ8+RjSS2m0m89cJ7EG8-VaccD91Aa2a32dJYY"
url = "https://www.ura.gov.sg/uraDataService/invokeUraDS?service=Car_Park_Details"

# Set up headers as in the successful curl request
headers = {
    'User-Agent': 'curl/8.7.1',
    'Accept': '*/*',
    'AccessKey': access_key,
    'Token': token,
}

# Make the GET request
response = requests.get(url, headers=headers)

# Debugging output
print("Request URL:", response.url)
print("Request Headers:", headers)

# Check the response
if response.status_code == 200:
    print("Response Data:", response.text)
else:
    print(f"Error: {response.status_code}, {response.reason}")
    print("Response Content:", response.content)  # Print the response content for more context
