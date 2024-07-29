import spotipy
import requests
import os
import pathlib
from dotenv import load_dotenv
from spotipy.oauth2 import SpotifyOAuth

# Load global variables from respective ".env folder"
main_dir = pathlib.Path(__file__).parent.parent.parent
env_path = main_dir / '.env'
load_dotenv(dotenv_path=env_path)

client_id = os.getenv('SPOTIFY_CLIENT_ID')
client_secret = os.getenv('SPOTIFY_CLIENT_SECRET')
redirect_uri = os.getenv('SPOTIFY_REDIRECT_URI')
apigw_url = os.getenv('SPOTIFY_AUTH_API_GATEWAY_ENDPOINT')
apigw_key = os.getenv('SPOTIFY_AUTH_API_GATEWAY_KEY')

sp_oauth = SpotifyOAuth(client_id=client_id,
    client_secret=client_secret,
    redirect_uri=redirect_uri,
    scope="user-library-read",
    cache_path='.cache')

print("Authenticating user...")

try:
    sp_oauth.get_access_token(as_dict=False) # remove "as_dict" when it is deprecated (DeprecationWarning is given when true as per 29/07/2024)
    token_info = sp_oauth.get_cached_token()
    access_token = token_info['access_token']
    refresh_token = token_info['refresh_token']
    print("Spotify authentication successful.")
except Exception as e:
    print(f"An error occurred while trying to authenticate user: {e}")

print("Sending access and refresh tokens to AWS API Gateway endpoint...")

response = requests.post(apigw_url,
    data = {
        "info": "Sending access and refresh tokens for Spotify authorisation"
    },
    headers = {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "x-api-key": apigw_key,
        "Content-Type": "application/json"
    })

# print(response.json())

#TO DO:
# - create proper response text from AWS side
# print("Awaiting response from AWS...")

os.remove(f"{main_dir}/.cache")



