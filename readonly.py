import requests
import json
import sys

url = 'https://api.jsonbin.io/v3/b/63647dfa0e6a79321e3e9fde/latest'
headers = {
  'Content-Type': 'application/json',
}


req = requests.get(url, json=None, headers=headers)
print(req.text)

print("\n")