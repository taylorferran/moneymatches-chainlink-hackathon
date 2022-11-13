import requests
import json
import sys

url = 'https://api.jsonbin.io/v3/b/6364c96f65b57a31e6acb928'
headers = {
  'Content-Type': 'application/json'
}

gameid = sys.argv[1]
winner = sys.argv[2]


req = requests.get(url, json=None, headers=headers)
print(req.text)

print("\n")

jsonobj = req.json()

print(jsonobj["record"][int(gameid)])

print("\n")

jsonobj["record"][int(gameid)]  = {"winner" : winner}


url = 'https://api.jsonbin.io/v3/b/6364c96f65b57a31e6acb928'
headers = {
  #'X-Master-Key': 
  'Content-Type': 'application/json'
}
req = requests.put(url, json=jsonobj["record"], headers=headers)
