// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


contract MoneyMatches {

    uint gameCount = 0;

    mapping (uint256 => Match) matchList;

    uint8 public constant pong = 1;
    uint8 public constant rps = 2;
    uint8 public constant chess = 3;

    struct Match {
        address Hero;
        address Villain; 	
        uint256 bounty;
        bool inProgress;
        address winner;
        uint8 gameType; 
    }

    function createGame(uint256 _bounty, uint8 _gameType) public payable returns(uint)
    {
        require(msg.value >= _bounty);
        //fill struct, hero = msg.sender, villian = 0x0, bounty = _bounty, 
        Match memory newMatch = Match (
        {
            Hero : msg.sender,
            Villain : 0x0000000000000000000000000000000000000000,
            bounty : _bounty,
            inProgress : true,
            winner : 0x0000000000000000000000000000000000000000,
            gameType : _gameType
        });
        // Add match data to mapping,
        matchList[gameCount] = newMatch;
        ++gameCount;
        //send eth to contract
        (bool sent,) = address(this).call{value : _bounty}("");
        require(sent);
        return(gameCount);
    }

    function acceptGame(uint256 gameID) public payable
    {
        Match memory matchToAccept = matchList[gameID];
        require(msg.sender.balance >= matchToAccept.bounty);
        // Set villain to the challenger
        matchToAccept.Villain = msg.sender;
        // Now we have bounties from both players
        matchToAccept.bounty += matchToAccept.bounty;
        matchList[gameID] = matchToAccept;
        //send eth to contract
        (bool sent,) = address(this).call{value : matchToAccept.bounty}("");
        require(sent);
    }


    // Somehow we need to update the winner to hero or villain
    // Then they can call this function to withdraw their bounty
    function settleGame(uint256 gameID) external
    {
     matchList[gameID].inProgress = false;
    }

    function cancelGameBeforeItHasStarted(uint256 gameID) external {

        Match memory matchToCancel = matchList[gameID];
        require(msg.sender == matchToCancel.Hero);
        require(matchToCancel.Villain == 0x0000000000000000000000000000000000000000);
        require(matchToCancel.inProgress == true);
        uint256 bountyToReturn = matchToCancel.bounty;
        matchToCancel.bounty = 0;
        matchToCancel.inProgress = false;
        matchList[gameID].bounty = 0;
        //transfer funds back to hero
        (bool sent,) = msg.sender.call{value : bountyToReturn}("");
        require(sent);
    }

}

