from web3 import Web3, HTTPProvider
import json

w3 = Web3(Web3.HTTPProvider("https://polygon-mumbai.g.alchemy.com/v2/8HjaBFF0lgG1fItufC4wH7qrqMNKveUs"))

print(w3.isConnected())


print(w3.eth.get_balance("0xa8430797A27A652C03C46D5939a8e7698491BEd6"))