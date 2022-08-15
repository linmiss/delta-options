// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
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

    return data.rate;
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
      require(
        !ethOptions[ID].canceled,
        'Option is canceled and cannot be bought'
      );
      require(
        ethOptions[ID].expiry > block.timestamp,
        'Option is expired and cannot be bought'
      );
      require(
        msg.value == ethOptions[ID].premium,
        'Incorrect amount of current coin sent for premium'
      );

      //Transfer premium payment to writer
      ethOptions[ID].writer.transfer(ethOptions[ID].premium);
      ethOptions[ID].buyer = payable(msg.sender);
    }

    if (tokenHash == croHash) {
      require(
        !croOptions[ID].canceled,
        'Option is canceled and cannot be bought'
      );
      require(
        croOptions[ID].expiry > block.timestamp,
        'Option is expired and cannot be bought'
      );
      require(
        msg.value == croOptions[ID].premium,
        'Incorrect amount of current coin sent for premium'
      );

      //Transfer premium payment to writer
      croOptions[ID].writer.transfer(croOptions[ID].premium);
      croOptions[ID].buyer = payable(msg.sender);
    }
  }

  function exercise(string memory token, uint256 ID)
    public
    payable
    supportCurrencrys(token)
  {
    bytes32 tokenHash = getTokenHash(token);

    if (tokenHash == ethHash) {
      require(ethOptions[ID].buyer == msg.sender, 'You do not own this option');
      require(!ethOptions[ID].exercised, 'Option has already been exercised');
      require(ethOptions[ID].expiry > block.timestamp, 'Option is expired');

      updatePrices();

      //Equivalent coin value using Chainlink feed
      uint256 latestCost = getLatestCost(
        ethOptions[ID].strike,
        ethPrice,
        ethOptions[ID].amount
      ); //move decimal 10 places right to account for 8 places of pricefeed

      //Buyer exercises option by paying strike*amount equivalent coin value
      require(
        msg.value == latestCost,
        'Incorrect coin amount sent to exercise'
      );
      //Pay writer the exercise cost
      ethOptions[ID].writer.transfer(latestCost);
      //Pay buyer contract amount of coin
      payable(msg.sender).transfer(ethOptions[ID].amount);
      ethOptions[ID].exercised = true;
    }

    if (tokenHash == croHash) {
      require(croOptions[ID].buyer == msg.sender, 'You do not own this option');
      require(!croOptions[ID].exercised, 'Option has already been exercised');
      require(croOptions[ID].expiry > block.timestamp, 'Option is expired');

      updatePrices();

      //Equivalent coin value using Chainlink feed
      uint256 latestCost = getLatestCost(
        croOptions[ID].strike,
        croPrice,
        croOptions[ID].amount
      ); //move decimal 10 places right to account for 8 places of pricefeed

      //Buyer exercises option by paying strike*amount equivalent coin value
      require(
        msg.value == latestCost,
        'Incorrect coin amount sent to exercise'
      );
      //Pay writer the exercise cost
      croOptions[ID].writer.transfer(latestCost);
      //Pay buyer contract amount of coin
      payable(msg.sender).transfer(croOptions[ID].amount);
      croOptions[ID].exercised = true;
    }
  }

  function cancelOption(string memory token, uint256 ID)
    public
    payable
    supportCurrencrys(token)
  {
    bytes32 tokenHash = getTokenHash(token);

    if (tokenHash == ethHash) {
      require(
        msg.sender == ethOptions[ID].writer,
        'You did not write this option'
      );

      //Must not have already been canceled or bought
      require(
        !ethOptions[ID].canceled && ethOptions[ID].buyer == address(0),
        'This option cannot be canceled'
      );
      ethOptions[ID].writer.transfer(ethOptions[ID].amount);
      ethOptions[ID].canceled = true;
    }

    if (tokenHash == croHash) {
      require(
        msg.sender == croOptions[ID].writer,
        'You did not write this option'
      );

      //Must not have already been canceled or bought
      require(
        !croOptions[ID].canceled && croOptions[ID].buyer == address(0),
        'This option cannot be canceled'
      );
      croOptions[ID].writer.transfer(croOptions[ID].amount);
      croOptions[ID].canceled = true;
    }
  }

  function retrieveExpiredFunds(string memory token, uint256 ID)
    public
    payable
    supportCurrencrys(token)
  {
    bytes32 tokenHash = getTokenHash(token);

    if (tokenHash == ethHash) {
      require(
        msg.sender == ethOptions[ID].writer,
        'You did not write this option'
      );
      //Must be expired, not exercised and not canceled
      require(
        ethOptions[ID].expiry <= block.timestamp &&
          !ethOptions[ID].exercised &&
          !ethOptions[ID].canceled,
        'This option is not eligible for withdraw'
      );
      ethOptions[ID].writer.transfer(ethOptions[ID].amount);
      //Repurposing canceled flag to prevent more than one withdraw
      ethOptions[ID].canceled = true;
    }

    if (tokenHash == croHash) {
      require(
        msg.sender == croOptions[ID].writer,
        'You did not write this option'
      );
      //Must be expired, not exercised and not canceled
      require(
        croOptions[ID].expiry <= block.timestamp &&
          !croOptions[ID].exercised &&
          !croOptions[ID].canceled,
        'This option is not eligible for withdraw'
      );
      croOptions[ID].writer.transfer(croOptions[ID].amount);
      //Repurposing canceled flag to prevent more than one withdraw
      croOptions[ID].canceled = true;
    }
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
