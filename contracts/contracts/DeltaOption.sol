// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/AggregatorV3Interface.sol';
import './interfaces/IStdReference.sol';
// Import this file to use console.log
import 'hardhat/console.sol';

contract DeltaOption {
  // Overflow safe operations
  using SafeMath for uint256;

  IStdReference internal bandProtocolFeed;

  //Interface for LINK token functions
  // LinkTokenInterface internal LINK;
  uint256 ethPrice;
  uint256 croPrice;

  //Precomputing hash of strings
  bytes32 ethHash = keccak256(abi.encodePacked('ETH'));
  bytes32 croHash = keccak256(abi.encodePacked('CRO'));
  address payable contractAddr;

  struct option {
    uint256 strike; // option strike price(USD) (18 decimal places)
    uint256 premium; // Fee in contract token that option writer charges
    uint256 expiry; // Unix timestamp of expiration time
    uint256 amount; // Amount of tokens the option contract is for
    bool exercised; // Has option been exercised
    bool canceled; // Has option been canceled
    uint256 id; // Unique ID of option, also array index
    uint256 latestCost; // Helper to show last updated cost to exercise
    address payable writer; //Issuer of option
    address payable buyer;
  }

  option[] public ethOptions;
  option[] public croOptions;

  modifier supportCurrencrys(string memory token) {
    bytes32 tokenHash = getTokenHash(token);
    require(
      tokenHash == ethHash || tokenHash == croHash,
      'Only ETH and CRO tokens are supported'
    );

    _;
  }

  constructor() {
    // Mainnet feed
    bandProtocolFeed = IStdReference(
      0xDA7a001b254CD22e46d3eAB04d937489c93174C3
    );

    contractAddr = payable(address(this));
  }

  function getUSDPrice(string memory _token)
    public
    view
    returns (uint256 rate)
  {
    IStdReference.ReferenceData memory data = bandProtocolFeed.getReferenceData(
      _token,
      'USD'
    );
    rate = data.rate;
  }

  function updatePrices() public {
    ethPrice = getUSDPrice('ETH');
    croPrice = getUSDPrice('CRO');
  }

  // Using 18 digits for the “decimals”.
  function getLatestCost(
    uint256 strike,
    uint256 spot,
    uint256 tknAmt
  ) public pure returns (uint256) {
    return strike.mul(tknAmt).div(spot.mul(10**10));
  }

  /**
   * @param token Takes which token, a strike price(USD per token w/18 decimal places)
   * @param strike Spot strike price(USD per token w/18 decimal places)
   * @param premium Fee in contract token that option writer charges
   * @param expiry expiration time
   * @param tknAmt How many tokens the contract is for
   */
  function writeOption(
    string memory token,
    uint256 strike,
    uint256 premium,
    uint256 expiry,
    uint256 tknAmt
  ) public payable supportCurrencrys(token) {
    bytes32 tokenHash = getTokenHash(token);

    updatePrices();

    if (tokenHash == ethHash) {
      require(msg.value == tknAmt, 'Incorrect amount of ETH supplied');
      uint256 latestCost = getLatestCost(strike, ethPrice, tknAmt); //current cost to exercise in ETH, decimal places corrected
      ethOptions.push(
        option(
          strike,
          premium,
          expiry,
          tknAmt,
          false,
          false,
          ethOptions.length,
          latestCost,
          payable(msg.sender),
          payable(address(0))
        )
      );
    }

    if (tokenHash == croHash) {
      require(msg.value == tknAmt, 'Incorrect amount of CRO supplied');
      uint256 latestCost = getLatestCost(strike, croPrice, tknAmt);
      croOptions.push(
        option(
          strike,
          premium,
          expiry,
          tknAmt,
          false,
          false,
          croOptions.length,
          latestCost,
          payable(msg.sender),
          payable(address(0))
        )
      );
    }
  }

  function buyOption(string memory token, uint256 ID)
    public
    payable
    supportCurrencrys(token)
  {
    bytes32 tokenHash = getTokenHash(token);

    if (tokenHash == ethHash) {
      _transferBuyer(ethOptions, ID);
    }

    if (tokenHash == croHash) {
      _transferBuyer(croOptions, ID);
    }
  }

  function exercise(string memory token, uint256 ID)
    public
    payable
    supportCurrencrys(token)
  {
    bytes32 tokenHash = getTokenHash(token);

    if (tokenHash == ethHash) {
      _exerciseOption(ethOptions, ID, ethPrice);
    }

    if (tokenHash == croHash) {
      _exerciseOption(croOptions, ID, croPrice);
    }
  }

  function cancelOption(string memory token, uint256 ID)
    public
    payable
    supportCurrencrys(token)
  {
    bytes32 tokenHash = getTokenHash(token);

    if (tokenHash == ethHash) {
      _cancel(ethOptions, ID);
    }

    if (tokenHash == croHash) {
      _cancel(croOptions, ID);
    }
  }

  function retrieveExpiredFunds(string memory token, uint256 ID)
    public
    payable
    supportCurrencrys(token)
  {
    bytes32 tokenHash = getTokenHash(token);

    if (tokenHash == ethHash) {
      _retrieveExpiredOption(ethOptions, ID);
    }

    if (tokenHash == croHash) {
      _retrieveExpiredOption(croOptions, ID);
    }
  }

  function _retrieveExpiredOption(option[] memory optionLists, uint256 ID)
    internal
  {
    require(
      msg.sender == optionLists[ID].writer,
      'You did not write this option'
    );
    //Must be expired, not exercised and not canceled
    require(
      optionLists[ID].expiry <= block.timestamp &&
        !optionLists[ID].exercised &&
        !optionLists[ID].canceled,
      'This option is not eligible for withdraw'
    );
    optionLists[ID].writer.transfer(optionLists[ID].amount);
    //Repurposing canceled flag to prevent more than one withdraw
    optionLists[ID].canceled = true;
  }

  function _cancel(option[] memory optionLists, uint256 ID) internal {
    require(
      msg.sender == optionLists[ID].writer,
      'You did not write this option'
    );
    //Must not have already been canceled or bought
    require(
      !optionLists[ID].canceled && optionLists[ID].buyer == address(0),
      'This option cannot be canceled'
    );
    optionLists[ID].writer.transfer(optionLists[ID].amount);
    optionLists[ID].canceled = true;
  }

  function _exerciseOption(
    option[] memory optionLists,
    uint256 ID,
    uint256 tokenPrice
  ) internal {
    require(optionLists[ID].buyer == msg.sender, 'You do not own this option');
    require(!optionLists[ID].exercised, 'Option has already been exercised');
    require(optionLists[ID].expiry > block.timestamp, 'Option is expired');

    updatePrices();

    //Equivalent coin value using Chainlink feed
    uint256 latestCost = getLatestCost(
      optionLists[ID].strike,
      tokenPrice,
      optionLists[ID].amount
    ); //move decimal 10 places right to account for 8 places of pricefeed

    //Buyer exercises option by paying strike*amount equivalent coin value
    require(msg.value == latestCost, 'Incorrect coin amount sent to exercise');
    //Pay writer the exercise cost
    optionLists[ID].writer.transfer(latestCost);
    //Pay buyer contract amount of coin
    payable(msg.sender).transfer(optionLists[ID].amount);
    optionLists[ID].exercised = true;
  }

  function _transferBuyer(option[] memory optionLists, uint256 ID) internal {
    require(
      !optionLists[ID].canceled,
      'Option is canceled and cannot be bought'
    );
    require(
      optionLists[ID].expiry > block.timestamp,
      'Option is expired and cannot be bought'
    );
    require(
      msg.value == optionLists[ID].premium,
      'Incorrect amount of current coin sent for premium'
    );

    //Transfer premium payment to writer
    optionLists[ID].writer.transfer(optionLists[ID].premium);
    optionLists[ID].buyer = payable(msg.sender);
  }

  function getTokenHash(string memory token) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(token));
  }

  function getEthOptions() public view returns (option[] memory) {
    return ethOptions;
  }

  function getCroOptions() public view returns (option[] memory) {
    return croOptions;
  }
}
