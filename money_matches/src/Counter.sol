// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


contract MoneyMatches {

    uint gameCount;

    mapping (uint => Match) matchList;

    struct Match {
        address Hero;
        address Villain; 	
        uint bounty;
        bool inProgress;
        address winner;
    }

    function createGame(int _bounty, enum gameType) // 1eth, RPS
    {
        check user has enough eth
        fill struct, hero = msg.sender, villian = 0x0, bounty = _bounty, 
        send eth to contract
    }

    function acceptGame(int gameid) 
    {
        Match x = matchList[gameid];
        require(balanceOf(msg.sender >= x.bounty)
        x.Villain = msg.sender
        x.inProgress = true;
        x.bounty += x.bounty;
        send eth to contract
    }


    // Somehow we need to update the winner to hero or villain
    // Then they can call this function to withdraw their bounty
    function settleGame()
    {
        
    }

    cancelGameBeforeItHasStarted(int gameId) {

        require(msg.sender = gameid.Match.Hero)
        require(gameid.Match.Villain = 0x0)
        require(gameid.Match.inProgress = false
        gameId.Match.bounty = 0;
        transfer funds back to hero
    }

}

