#########################################################################################
# This script is used as utility to update the json bin with the winner of the game.    #
#                                                                                      #
# We get the current version of the json bin with an HTTP get, all gameIDs match up   #
# up to it's array number e.g, array entry [4] == gameID 4, the json looks like this #
#####################################################################################
"""
[
  {
    "winner": "0x26fA48f0407DBa513d7AD474e95760794e5D698E"
  },
  {
    "winner": "0xa8430797A27A652C03C46D5939a8e7698491BEd6"
  },
  {
    "winner": "0x26fA48f0407DBa513d7AD474e95760794e5D698E"
  },
  {
    "winner": "0x26fA48f0407DBa513d7AD474e95760794e5D698E"
  },
  {
    "winner": "0x0"
  },
  {
    "winner": "0x0"
  },
]
"""
###################################################################################
# So if we called this script with arguments (4, "0x321"), the 4th entry would be  #
# updated from 0x0 to 0x321. After that we can call the settle game function        #
# on the front end, which will send a link request to read from our json bin and     #
# payout the wager to the winner. This method is not scalable, but a good prototype!  #
########################################################################################


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

jsonobj = req.json()

jsonobj["record"][int(gameid)]  = {"winner" : winner}

# Master key removed for the github review incase bots somehow fuck with my json bin
  headers = {
  #'X-Master-Key':,
  'Content-Type': 'application/json'
}
req = requests.put(url, json=jsonobj["record"], headers=headers)
