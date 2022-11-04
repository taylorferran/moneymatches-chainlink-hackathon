import requests
import json
import sys

url = 'https://api.jsonbin.io/v3/b/63647dfa0e6a79321e3e9fde/latest'
headers = {
  'X-Master-Key': #####

gameid = sys.argv[1]
winner = sys.argv[2]


req = requests.get(url, json=None, headers=headers)
print(req.text)

print("\n")

jsonobj = req.json()
data = jsonobj["record"]
#data["winner"].append("0x0")
#data += ("winner : ")

print(data)

print("\n")

testJson = json.dumps(data)
testJson2 = json.loads(testJson)

x = {gameid : winner}

testJson2.update(x)

print(testJson2)


url = 'https://api.jsonbin.io/v3/b/63647dfa0e6a79321e3e9fde'
headers = {
  'Content-Type': 'application/json',
  'X-Master-Key': ####
req = requests.put(url, json=testJson2, headers=headers)
