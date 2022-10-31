// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


contract MoneyMatches {

    uint gameCount = 1;

    mapping (address => string) playerCurrentMatch;
    mapping (string => bool) nameAvailable;
    mapping (string => Match) matchList;


    struct Match {
        address Hero;
        address Villain; 	
        uint256 bounty;
        address winner;
    }

    function createGame(uint256 _bounty, string memory _gameName) public payable returns(string memory)
    {
        require(msg.value >= _bounty);
        require(!nameAvailable[_gameName]);
        require(keccak256(abi.encodePacked((playerCurrentMatch[msg.sender]))) == keccak256(abi.encodePacked((""))));
        Match memory newMatch = Match (
        {
            Hero : msg.sender,
            Villain : 0x0000000000000000000000000000000000000000,
            bounty : _bounty,
            winner : 0x0000000000000000000000000000000000000000
        });
        // Add match data to mapping,
        matchList[_gameName] = newMatch;
        playerCurrentMatch[msg.sender] = _gameName;
        nameAvailable[_gameName] = true;
        //send eth to contract
        (bool sent,) = address(this).call{value : _bounty}("");
        require(sent);
        return(_gameName);
    }

    function acceptGame(string memory _gameName) public payable
    {
        Match memory matchToAccept = matchList[_gameName];
        require(msg.sender.balance >= matchToAccept.bounty);
        require(keccak256(abi.encodePacked((playerCurrentMatch[msg.sender]))) == keccak256(abi.encodePacked((""))));
        // Set villain to the challenger
        matchToAccept.Villain = msg.sender;
        // Now we have bounties from both players
        matchToAccept.bounty += matchToAccept.bounty;
        matchList[_gameName] = matchToAccept;
        playerCurrentMatch[msg.sender] = _gameName;
        //send eth to contract
        (bool sent,) = address(this).call{value : matchToAccept.bounty}("");
        require(sent);
    }

 
    // Somehow we need to update the winner to hero or villain
    // Then they can call this function to withdraw their bounty
    function settleGame(string memory _gameName) public {

        require(msg.sender == matchList[_gameName].winner);
        playerCurrentMatch[msg.sender] = "";
        nameAvailable[_gameName] = false;


        uint256 bountyToReturn = matchList[_gameName].bounty;
        matchList[_gameName].bounty = 0;
        (bool sent,) = msg.sender.call{value : bountyToReturn}("");
        require(sent);
    }

    function cancelGameBeforeItHasBeenAccepted(string memory _gameName) public {

        Match memory matchToCancel = matchList[_gameName];
        require(msg.sender == matchToCancel.Hero);
        require(matchToCancel.Villain == 0x0000000000000000000000000000000000000000);
        require(matchToCancel.bounty > 0);
        uint256 bountyToReturn = matchToCancel.bounty;
        matchToCancel.bounty = 0;
        nameAvailable[_gameName] = false;

        matchList[_gameName].bounty = 0;
        //transfer funds back to hero
        (bool sent,) = msg.sender.call{value : bountyToReturn}("");
        require(sent);
    }

}

