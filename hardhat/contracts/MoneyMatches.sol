// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract MoneyMatches is ChainlinkClient, ConfirmedOwner {
    
    // link variables
    using Chainlink for Chainlink.Request;
    bytes32 private jobId;
    uint256 private fee;

    event RequestMultipleFulfilled(bytes32 indexed requestId, string name, string winner);


    uint gameCount = 1;

    mapping (address => string) playerCurrentMatch;
    mapping (string => bool) nameAvailable;
    mapping (string => Match) matchList;

    struct Match {
        address payable Hero;
        address payable Villain; 	
        uint256 wager;
        address winner;
    }

    // Need to find the correct addresses for mumbai, and job id
    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        jobId = '53f9755920cd451a8fe46f5087468395';
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }


    function createGame(uint256 _wager, string memory _gameName) public payable returns(string memory)
    {
        require(msg.value >= _wager);
        require(!nameAvailable[_gameName]);
        require(keccak256(abi.encodePacked((playerCurrentMatch[msg.sender]))) == keccak256(abi.encodePacked((""))));
        Match memory newMatch = Match (
        {
            Hero : payable(msg.sender),
            Villain : payable(0x0000000000000000000000000000000000000000),
            wager : _wager,
            winner : payable(0x0000000000000000000000000000000000000000)
        });
        // Add match data to mapping,
        matchList[_gameName] = newMatch;
        playerCurrentMatch[msg.sender] = _gameName;
        nameAvailable[_gameName] = true;
        //send eth to contract
        (bool sent,) = address(this).call{value : _wager}("");
        require(sent);
        return(_gameName);
    }

    function acceptGame(string memory _gameName) public payable
    {
        Match memory matchToAccept = matchList[_gameName];
        require(msg.sender.balance >= matchToAccept.wager);
        require(keccak256(abi.encodePacked((playerCurrentMatch[msg.sender]))) == keccak256(abi.encodePacked((""))));
        // Set villain to the challenger
        matchToAccept.Villain = payable(msg.sender);
        // Now we have wagers from both players
        matchToAccept.wager += matchToAccept.wager;
        matchList[_gameName] = matchToAccept;
        playerCurrentMatch[msg.sender] = _gameName;
        //send eth to contract
        (bool sent,) = address(this).call{value : matchToAccept.wager}("");
        require(sent);
    }

 
    // Somehow we need to update the winner to hero or villain
    // Then they can call this function to withdraw their wager
    function settleGame(string memory _gameName) public {

        require(msg.sender == matchList[_gameName].winner);
        playerCurrentMatch[msg.sender] = "";
        nameAvailable[_gameName] = false;


        uint256 wagerToReturn = matchList[_gameName].wager;
        matchList[_gameName].wager = 0;
        (bool sent,) = msg.sender.call{value : wagerToReturn}("");
        require(sent);
    }

    function cancelGameBeforeItHasBeenAccepted(string memory _gameName) public {

        Match memory matchToCancel = matchList[_gameName];
        require(msg.sender == matchToCancel.Hero);
        require(matchToCancel.Villain == 0x0000000000000000000000000000000000000000);
        require(matchToCancel.wager > 0);
        uint256 wagerToReturn = matchToCancel.wager;
        matchToCancel.wager = 0;
        nameAvailable[_gameName] = false;

        matchList[_gameName].wager = 0;
        //transfer funds back to hero
        (bool sent,) = msg.sender.call{value : wagerToReturn}("");
        require(sent);
    }

    // LINK FUNCTIONS

    /**
     * @notice Request mutiple parameters from the oracle in a single transaction
     */
    function requestMultipleParameters() public {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillMultipleParameters.selector
        );
        // Need to update to use my own json
        req.add('urlNAME', 'https://api.jsonbin.io/v3/qs/635f99d80e6a79321e3a292b');
        req.add('pathNAME', 'NAME');
        req.add('urlWINNER', 'https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD');
        req.add('pathWINNER', 'WINNNER');
        sendChainlinkRequest(req, fee); // MWR API.
    }

    /**
     * @notice Fulfillment function for multiple parameters in a single request
     * @dev This is called by the oracle. recordChainlinkFulfillment must be used.
     */
    function fulfillMultipleParameters(
        bytes32 requestId,
        string memory nameResponse,
        string memory winnerResponse

    ) public recordChainlinkFulfillment(requestId) {
        emit RequestMultipleFulfilled(requestId, nameResponse, winnerResponse);
        // Need to convert winnerResponse to an address
        matchList[nameResponse].winner = address(0);
        winnerResponse = winnerResponse;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

}

