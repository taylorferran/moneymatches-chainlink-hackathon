// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract MoneyMatches is ChainlinkClient, ConfirmedOwner {
    

    string public testOne;
    string public testTwo;

    // link variables
    using Chainlink for Chainlink.Request;
    bytes32 private jobId;
    uint256 private fee;

    event RequestWinner(bytes32 indexed requestId, string id);


    uint gameCount = 1;
    uint matchBeingProcessed;

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
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        jobId = '7d80a6386ef543a3abb52817f6707e3b';
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }


    function createGame(uint256 _wager) public payable returns(uint)
    {
        require(msg.value >= _wager);
        require(playerCurrentMatch[msg.sender] == 0);
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
        playerCurrentMatch[msg.sender] = gameCount;
        //send eth to contract
        (bool sent,) = address(this).call{value : _wager}("");
        require(sent);
        ++gameCount;
        return(gameCount);
    }

    function acceptGame(uint _gameID) public payable
    {
        Match memory matchToAccept = matchList[_gameID];
        require(msg.sender.balance >= matchToAccept.wager);
        require(playerCurrentMatch[msg.sender] == 0);
        // Set villain to the challenger
        matchToAccept.Villain = payable(msg.sender);
        // Now we have wagers from both players
        matchToAccept.wager += matchToAccept.wager;
        matchList[_gameID] = matchToAccept;
        playerCurrentMatch[msg.sender] = _gameID;
        //send eth to contract
        (bool sent,) = address(this).call{value : matchToAccept.wager}("");
        require(sent);
    }

 
    // Somehow we need to update the winner to hero or villain
    // Then they can call this function to withdraw their wager
    function settleGame(uint _gameID, string memory _winner) public {

        Match memory matchToProcess = matchList[_gameID];

        playerCurrentMatch[matchToProcess.Hero] = 0;
        playerCurrentMatch[matchToProcess.Villain] = 0;

        matchToProcess.winner = parseAddr(_winner);

        uint256 wagerToReturn = matchToProcess.wager;
        matchToProcess.paidOut = true;
        matchList[_gameID] = matchToProcess;
        //address winner = 0x26fA48f0407DBa513d7AD474e95760794e5D698E; //_winner;
        (bool sent,) = matchToProcess.winner.call{value : wagerToReturn}("");
        require(sent);
    }

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
        require(sent);
    }

    // LINK FUNCTIONS
   
    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data which is located in a list
     */
    function requestWinnerFromGameID(uint _gameID) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        require(matchBeingProcessed == 0);
        require(matchList[_gameID].paidOut == false);

        // Set the URL to perform the GET request on
        //req.add('get', 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&per_page=10');
        req.add('get', 'https://api.jsonbin.io/v3/qs/636391452b3499323bf3d6a7');
        
        
        string memory requestString = string.concat('record,', Strings.toString(_gameID), ',winner');
        testTwo = requestString;
        req.add('path', requestString);

        matchBeingProcessed = _gameID;

        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of string
     */
    function fulfill(bytes32 _requestId, string memory _winner) public recordChainlinkFulfillment(_requestId) {
        emit RequestWinner(_requestId, _winner);
        testOne = _winner;
        settleGame(matchBeingProcessed, _winner);
        matchBeingProcessed = 0;
    }


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

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

    function withdraw() public onlyOwner {
        (bool sent,) = msg.sender.call{value : address(this).balance}("");
        require(sent);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}

