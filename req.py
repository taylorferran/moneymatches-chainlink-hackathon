import requests
import sys
url = 'https://api.jsonbin.io/v3/b/63647dfa0e6a79321e3e9fde'
headers = {
  'Content-Type': 'application/json',
  'X-Master-Key': ####
}

gameid = sys.argv[1]
winner = sys.argv[2]
data = {gameid: winner}

req = requests.put(url, json=data, headers=headers)
print(req.text)
