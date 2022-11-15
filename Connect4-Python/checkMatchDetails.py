##########################################################################################
# This is a script to do some verification on whether a valid match can be played or not. #
#                                                                                         #
# Game cannot start if:                                                                  #
# - Hero address isn't correct                                                          #
# - Villain address isn't correct                                                      #
# - Match has been paid out already                                                     #
# - Match has been played already                                                         #
#                                                                                         #
# The first three we verify by reading off of the smart contract using web3 py, the last #
# we just check the json bin to see if there's a winner for this match yet.             #
######################################################################################## 

import sys
import web3
import requests
import json


gameid = sys.argv[1]
hero = sys.argv[2]
villain = sys.argv[3]
abi = [
    {
      "inputs": [],
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
    {
      "anonymous": False,
      "inputs": [
        {
          "indexed": True,
          "internalType": "bytes32",
          "name": "id",
          "type": "bytes32"
        }
      ],
      "name": "ChainlinkCancelled",
      "type": "event"
    },
    {
      "anonymous": False,
      "inputs": [
        {
          "indexed": True,
          "internalType": "bytes32",
          "name": "id",
          "type": "bytes32"
        }
      ],
      "name": "ChainlinkFulfilled",
      "type": "event"
    },
    {
      "anonymous": False,
      "inputs": [
        {
          "indexed": True,
          "internalType": "bytes32",
          "name": "id",
          "type": "bytes32"
        }
      ],
      "name": "ChainlinkRequested",
      "type": "event"
    },
    {
      "anonymous": False,
      "inputs": [
        {
          "indexed": True,
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "indexed": True,
          "internalType": "address",
          "name": "to",
          "type": "address"
        }
      ],
      "name": "OwnershipTransferRequested",
      "type": "event"
    },
    {
      "anonymous": False,
      "inputs": [
        {
          "indexed": True,
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "indexed": True,
          "internalType": "address",
          "name": "to",
          "type": "address"
        }
      ],
      "name": "OwnershipTransferred",
      "type": "event"
    },
    {
      "anonymous": False,
      "inputs": [
        {
          "indexed": True,
          "internalType": "bytes32",
          "name": "requestId",
          "type": "bytes32"
        },
        {
          "indexed": False,
          "internalType": "string",
          "name": "winner",
          "type": "string"
        }
      ],
      "name": "RequestWinner",
      "type": "event"
    },
    {
      "stateMutability": "payable",
      "type": "fallback"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_gameID",
          "type": "uint256"
        }
      ],
      "name": "acceptGame",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "acceptOwnership",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_gameID",
          "type": "uint256"
        }
      ],
      "name": "cancelGameBeforeItHasBeenAccepted",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "cancelMatchBeingProcessed",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_wager",
          "type": "uint256"
        }
      ],
      "name": "createGame",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "bytes32",
          "name": "_requestId",
          "type": "bytes32"
        },
        {
          "internalType": "string",
          "name": "_winner",
          "type": "string"
        }
      ],
      "name": "fulfill",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "gameSettled",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "matchBeingProcessed",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "name": "matchList",
      "outputs": [
        {
          "internalType": "address payable",
          "name": "Hero",
          "type": "address"
        },
        {
          "internalType": "address payable",
          "name": "Villain",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "wager",
          "type": "uint256"
        },
        {
          "internalType": "address",
          "name": "winner",
          "type": "address"
        },
        {
          "internalType": "bool",
          "name": "paidOut",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "owner",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        }
      ],
      "name": "playerCurrentMatch",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "ran",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_gameID",
          "type": "uint256"
        }
      ],
      "name": "requestWinnerFromGameID",
      "outputs": [
        {
          "internalType": "bytes32",
          "name": "requestId",
          "type": "bytes32"
        }
      ],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "uint256",
          "name": "_gameID",
          "type": "uint256"
        },
        {
          "internalType": "string",
          "name": "_winner",
          "type": "string"
        }
      ],
      "name": "settleGame",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "testOne",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "testTwo",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "to",
          "type": "address"
        }
      ],
      "name": "transferOwnership",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "withdraw",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "withdrawLink",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "stateMutability": "payable",
      "type": "receive"
    }
  ]

def main():

  url = 'https://api.jsonbin.io/v3/b/6364c96f65b57a31e6acb928'
  headers = {
    'Content-Type': 'application/json'
  }

  canPlayGame = True

  req = requests.get(url, json=None, headers=headers)
  jsonobj = req.json()

  winnerField = jsonobj["record"][int(gameid)]["winner"]
  if (jsonobj["record"][int(gameid)]["winner"] != "0x0"):
    print("MATCH HAS ALREADY BEEN PLAYED")
    canPlayGame = False
    return canPlayGame


  ALCHEMY_URL="https://eth-goerli.g.alchemy.com/v2/dYfnm53DsDD80Wmr3foRg5j8Y09i1XRv"
  w3 = web3.Web3(web3.HTTPProvider(ALCHEMY_URL))


  moneyMatchesContract = "0x67624afC73c953B69Bc0d9C5C3c829253BeC75D7"
  moneyMatches = w3.eth.contract(address=moneyMatchesContract, abi=abi)

  gameDetails = moneyMatches.functions.matchList((int(gameid, 0))).call()


  if (gameDetails[0] == hero):
      print("HERO OK FOR THIS MATCH ID")
  else:
      print("HERO INVALID FOR THIS MATCH ID")
      canPlayGame = False
      sys.exit(canPlayGame)

  if (gameDetails[1] == villain):
      print("VILLAIN OK FOR THIS MATCH ID")
  else:
      print("VILLAIN INVALID FOR THIS MATCH ID")
      canPlayGame = False
      sys.exit(canPlayGame)

  if(gameDetails[4] == False):
      print("GAME NOT PLAYED YET AND ADDRESSES OK - LAUNCHING GAME")
  else:
      print("GAME ALREADY PAID OUT")
      canPlayGame = False
  sys.exit(canPlayGame)


if __name__ == "__main__":
  main()
  
