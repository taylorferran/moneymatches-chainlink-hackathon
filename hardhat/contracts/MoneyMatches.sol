// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract MoneyMatches is ChainlinkClient, ConfirmedOwner {
    

    string public testOne;
    string public testTwo;
    string public ran;
    string public gameSettled;

    // Link variables
    using Chainlink for Chainlink.Request;
    bytes32 private jobId;
    uint256 private fee;

    event RequestWinner(bytes32 indexed requestId, string winner);

    // To keep track of 
    uint gameCount = 1;
    uint public matchBeingProcessed;

    mapping (address => uint) public playerCurrentMatch;
    mapping (uint => Match) public matchList;

    struct Match {
        address payable Hero;
        address payable Villain; 	
        uint256 wager;
        address winner;
        bool paidOut;
    }

    // Need to find the correct addresses for mumbai, and job id
    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = '7d80a6386ef543a3abb52817f6707e3b';
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }


    function createGame(uint256 _wager) public payable returns(uint)
    {
        // Check right amount of eth sent
        require(msg.value >= _wager);
        // Check player isn't already in a game
        require(playerCurrentMatch[msg.sender] == 0);
        // Create new match struct and add our address
        Match memory newMatch = Match (
        {
            Hero : payable(msg.sender),
            Villain : payable(0x0000000000000000000000000000000000000000),
            wager : msg.value,
            winner : payable(0x0000000000000000000000000000000000000000),
            paidOut : false
        });
        // Add match data to mapping,
        matchList[gameCount] = newMatch;
        // Assign this match to our address
        playerCurrentMatch[msg.sender] = gameCount;
        //send eth to contract
        (bool sent,) = address(this).call{value : _wager}("");
        require(sent);
        ++gameCount;
        return(gameCount);
    }

    function acceptGame(uint _gameID) public payable
    {
        // Store match in a local variable
        Match memory matchToAccept = matchList[_gameID];
        // Check we have enough to wager
        require(msg.sender.balance >= matchToAccept.wager);
        // Check player isn't already in a game
        require(playerCurrentMatch[msg.sender] == 0);
        // Set villain to the challenger
        matchToAccept.Villain = payable(msg.sender);
        // Add wager from villain
        matchToAccept.wager += matchToAccept.wager;
        // Assign local variable to storage
        matchList[_gameID] = matchToAccept;
        // Assign this match to our address
        playerCurrentMatch[msg.sender] = _gameID;
        // Send eth to contract
        (bool sent,) = address(this).call{value : matchToAccept.wager}("");
        require(sent);
    }


    // Called by the function which fullfils our link request
    function settleGame(uint _gameID, string memory _winner) public {

        Match memory matchToProcess = matchList[_gameID];

        playerCurrentMatch[matchToProcess.Hero] = 0;
        playerCurrentMatch[matchToProcess.Villain] = 0;

        matchToProcess.winner = parseAddr(_winner);

        uint256 wagerToReturn = matchToProcess.wager;
        matchToProcess.paidOut = true;
        matchList[_gameID] = matchToProcess;
        (bool sent,) = matchToProcess.winner.call{value : wagerToReturn}("");
        require(sent);
    }

    // Allow the hero to cancel the game and remove their wager before
    // the game as been accepted by anyone 
    function cancelGameBeforeItHasBeenAccepted(uint _gameID) public {

        Match memory matchToCancel = matchList[_gameID];
        require(msg.sender == matchToCancel.Hero);
        require(matchToCancel.Villain == 0x0000000000000000000000000000000000000000);
        require(matchToCancel.wager > 0);
        require(matchToCancel.paidOut == false);
        uint256 wagerToReturn = matchToCancel.wager;
        matchToCancel.wager = 0;
        matchToCancel.paidOut = true;

        playerCurrentMatch[msg.sender] = 0;

        matchList[_gameID].wager = 0;
        //transfer funds back to hero
        (bool sent,) = msg.sender.call{value : wagerToReturn}("");

    }

    // LINK FUNCTIONS
   
    // Here we pass in the gameID once it has finished, it will then get the corresponding
    // match stored in our json bin, 
    function requestWinnerFromGameID(uint _gameID) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        require(matchBeingProcessed == 0);
        require(matchList[_gameID].paidOut == false);

        // Set the URL to perform the GET request on
        req.add('get', 'https://api.jsonbin.io/v3/b/6364c96f65b57a31e6acb928');

        string memory requestString = string.concat('record,', Strings.toString(_gameID), ',winner');
        req.add('path', requestString);

        // Currently we only allow for one game to be processed at a time, we set the gameID
        // we want to process here so we can use it in the fulfill function
        matchBeingProcessed = _gameID;

        return sendChainlinkRequest(req, fee);
    }

    // Receive response as a string, use this to assign the winner and settle the game
    function fulfill(bytes32 _requestId, string memory _winner) public recordChainlinkFulfillment(_requestId) {
        emit RequestWinner(_requestId, _winner);
        settleGame(matchBeingProcessed, _winner);
        // Set match being processed to 0 so another 
        matchBeingProcessed = 0;
    }

    // Just in case something goes wrong with the fulfill function, we can use this
    // to reset matchBeingProcessed to 0 to avoid a deadlock
    function cancelMatchBeingProcessed() public onlyOwner {
        matchBeingProcessed = 0;
    }

    // Helper function because we're getting the address as a string. From old oracilize/provable 
    // code but I could not find it anywhere except stackoverflow so just pasted it in lol
    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }


    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

    function withdraw() public onlyOwner {
        (bool sent,) = msg.sender.call{value : address(this).balance}("");
        require(sent);
    }

    receive() external payable {}
    fallback() external payable {}

}

