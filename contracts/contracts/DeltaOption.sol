// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/AggregatorV3Interface.sol';
// Import this file to use console.log
import 'hardhat/console.sol';

contract DeltaOption {
  // Overflow safe operations
  using SafeMath for uint256;

  AggregatorV3Interface internal ethFeed;
  AggregatorV3Interface internal croFeed;

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
    // ETH/USD Mainnet feed
    ethFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    // CRO/USD Mainnet feed
    croFeed = AggregatorV3Interface(0x00Cb80Cf097D9aA9A3779ad8EE7cF98437eaE050);

    contractAddr = payable(address(this));
  }

  function getCroPrice() public view returns (uint256) {
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = croFeed.latestRoundData();

    require(updatedAt - startedAt > 0, 'Round not complete');

    return uint256(answer);
  }

  function getEthPrice() public view returns (uint256) {
    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) = ethFeed.latestRoundData();

    require(updatedAt - startedAt > 0, 'Round not complete');

    return uint256(answer);
  }

  function updatePrices() public {
    ethPrice = getEthPrice();
    croPrice = getCroPrice();
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
      _exerciseOption(ethOptions, ID);
    }

    if (tokenHash == croHash) {
      _exerciseOption(croOptions, ID);
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

  function _exerciseOption(option[] memory optionLists, uint256 ID) internal {
    require(optionLists[ID].buyer == msg.sender, 'You do not own this option');
    require(!optionLists[ID].exercised, 'Option has already been exercised');
    require(optionLists[ID].expiry > block.timestamp, 'Option is expired');

    updatePrices();
    //Cost to exercise
    uint256 exerciseValue = optionLists[ID].strike * optionLists[ID].amount;

    //Equivalent coin value using Chainlink feed
    uint256 equivCoin = exerciseValue.div(ethPrice.mul(10**10)); //move decimal 10 places right to account for 8 places of pricefeed

    //Buyer exercises option by paying strike*amount equivalent coin value
    require(msg.value == equivCoin, 'Incorrect coin amount sent to exercise');
    //Pay writer the exercise cost
    optionLists[ID].writer.transfer(equivCoin);
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
}
