Money Matches is a competitive gamefi project aimed at building a matchmaking platform. The goal for this project was to build a platform that lets two players create and accept a wager match by both putting up X amount of ETH, play the match out on another platform, then the winner can redeem their winningsn via the smart contract. The overall framework has been put in place for this, although it wasn't hooked up to an in browser game to have two players play online (this is the next step I'm currently working on).

It's built and deployed on Goerli for the Chainlink hackathon.

What it does
At present:

Users can create games by specifying a wager in eth. This is done by signing a txn on the frontend which creates a match and stores it in the smart contract storage.
Users can accept games which another player has created by specifying the gameID, users can only accept games which have not been played/paidout/cancelled.
Users can cancel a game they have created before it has been accepted to get their wager back.
Users can play the game off chain in the python gamepy game, this verifies that a game has been created and has not been played yet. Upon winning this game the winner is pushed to a json bin.
Winner can then settle the game on the frontend and receive their winnings.
You can build and run it by syncing down this repo and running:

cd frontend

npm i

npm run dev
