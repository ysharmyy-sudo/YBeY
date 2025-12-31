import requests
import json

url = "http://127.0.0.1:5000/api/register"

payload = {
    "username": "testuser_db_check_py",
    "email": "test_db_py@example.com",
    "password": "secret_password",
    "confirm_password": "secret_password",
    "remember_me": True
}

headers = {
    "Content-Type": "application/json"
}

try:
    print(f"Sending request to {url}...")
    response = requests.post(url, json=payload)
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.text}")
    
    if response.status_code == 200:
        print("\nSUCCESS: User registered successfully via API!")
    elif response.status_code == 400 and "already exists" in response.text:
         print("\nSUCCESS: Database connected (User already exists)!")
    else:
        print("\nFAILED: Something went wrong.")
except Exception as e:
    print(f"\nERROR: Could not connect to API. Is the server running? {e}")
