import requests

url = "https://instagram47.p.rapidapi.com/public_user_posts/"

querystring = {"userid":"userid"}

headers = {
    'x-rapidapi-key': "key",
    'x-rapidapi-host': "host"
    }

response = requests.request("GET", url, headers=headers, params=querystring)

print(response.text)