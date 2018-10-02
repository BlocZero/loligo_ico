pragma solidity ^0.4.24;


import "./SafeMath.sol";
import "./LoligoToken.sol";
import "./Pausable.sol";
import "./PullPayment.sol";
import "./Whitelist.sol";
import "./TokenBonus.sol";


/*
*  Crowdsale Smart Contract for the Loligo project
*  Author: Yosra Helal yosra.helal@bechainsc.com
*/


contract Crowdsale is Pausable, PullPayment, Whitelist, TokenBonus {
    using SafeMath for uint256;


    // address for testing to change
    address private wallet = 0x94c921261EA20Ef9Bab3600528A29fEC0913eDf7;   // ETH wallet

    // LLG token
    LoligoToken public token;

    // Crowdsale period
    uint256 public rate;                                                 // Rate LLG token per ether
    uint256 public totalTokensForSale;                                   // LLG tokens will be sold in Crowdsale
    uint256 public  maxFundingGoal;                                      // Maximum goal in Ether raised
    uint256 public  minFundingGoal;                                      // Minimum funding goal in Ether raised
    bool public crowdsale;                                               // Crowdsale period

    // Refund Period
    uint256 public  REFUNDSTART;                                        // epoch timestamp representing the refundPeriodStart date of refund period
    uint256 public  REFUNDEADLINE;                                      // epoch timestamp representing the end date of refund period

    // Sales params
    uint256 public savedBalance;                                        // Total amount raised in ETH
    uint256 public savedTokenBalance;                                   // Total sold tokens for presale
    mapping (address => uint256) balances;                              // Balances in incoming Ether

    // Events
    event Contribution(address indexed _contributor, uint256 indexed _value, uint256 indexed _tokens);     // Event to record new contributions
    event PayEther(address indexed _receiver, uint256 indexed _value, uint256 indexed _timestamp);         // Event to record each time Ether is paid out
    event BurnTokens(uint256 indexed _value, uint256 indexed _timestamp);                                  // Event to record when tokens are burned.


    // Initialization
    constructor(address _token) public {
        // add address of the specific contract
        token = LoligoToken(_token);
    }


    // Fallbck function for contribution
    function () public payable whenNotPaused {
        if (msg.sender != wallet) {
          require(crowdsale);
          _buyTokens(msg.sender);
        }else {
          emit PayEther(address(this), msg.value, block.timestamp);
        }
    }

    /***********************************
    *       Public functions for the   *
    *           Crowdsale period       *
    ************************************/

    // Function to start crowdsale period & set up params
    function startCrowdsale(uint256 _rate, uint256 _maxCap, uint256 _minCap) public onlyOwner {
        rate = _rate;
        maxFundingGoal = _maxCap;
        minFundingGoal = _minCap;
        crowdsale = true;
    }

    // Function to close the crowdsale period
    function closeCrowdsale() public onlyOwner{
      require(crowdsale);
	    crowdsale = false;
      REFUNDSTART = block.timestamp;
	    REFUNDEADLINE = REFUNDSTART + 30 days;
    }

    // Function to check if crowdsale is complete (
    function isComplete() public view returns (bool) {
        return (savedBalance >= maxFundingGoal) || (savedTokenBalance >= totalTokensForSale) || (crowdsale == false);
    }

    // Function to check if crowdsale has been successful
    // (has incoming contribution balance met, or exceeded the minimum goal?)
    function isSuccessful() public view returns (bool) {
        return (savedBalance >= minFundingGoal);
    }

    // Function to check the refund period is over
    function refundPeriodOver() public view returns (bool) {
        return (block.timestamp > REFUNDEADLINE);
    }

    // Function to check the refund period is over
    function refundPeriodStart() public view returns (bool) {
        return (block.timestamp > REFUNDSTART);
    }

    // Only owner will finalize the crowdsale
    function finalize() public onlyOwner {
        require(crowdsale);
        crowdsale = false;
        REFUNDSTART = block.timestamp;
        REFUNDEADLINE = REFUNDSTART + 30 days;
    }

    // Function to pay out
    function payout(address _newOwner) public onlyOwner {
        require((isSuccessful() && isComplete()) || refundPeriodOver());
        if (isSuccessful() && isComplete()) {
            uint256 tokensToBurn =  token.balanceOf(address(this)).sub(savedBonusToken);
            require(token.burn(tokensToBurn));
            transferTokenOwnership(_newOwner);
            crowdsale = false;
        }else {
            if (refundPeriodOver()) {
                wallet.transfer(address(this).balance);
                emit PayEther(wallet, address(this).balance, now);
                require(token.burn(token.balanceOf(address(this))));
                transferTokenOwnership(_newOwner);
            }
        }
    }

    // Function to transferOwnership of the LLG token
    function transferTokenOwnership(address _newOwner) public onlyOwner {
        token.transferOwnership(_newOwner);
    }

    /***********************************
    *           Refund period          *
    ************************************/

    /* When MIN_CAP is not reach the smart contract will be credited to make refund possible by backers
     * 1) backer call the "refund" function of the Crowdsale contract
     * 2) backer call the "withdraw" function of the Crowdsale contract to get a refund in ETH
     */
    function refund() public {
        require(!isSuccessful());
        require(refundPeriodStart());
        require(!refundPeriodOver());
        require(balances[msg.sender] > 0);
        uint256 amountToRefund = balances[msg.sender].mul(95).div(100);
        balances[msg.sender] = 0;
        asyncSend(msg.sender, amountToRefund);
    }

    // function of the Crowdsale contract to get a refund in ETH
    function withdraw() public {
        withdrawPayments();
        savedBalance = address(this).balance;
    }


    /***************************************
    *          internal functions          *
    ****************************************/

    // Contribute Function, accepts incoming payments and tracks balances for each contributors
    function _buyTokens(address _beneficiary) internal {
        require(!isComplete());

        if (isWhitelisted(_beneficiary)) {
            if (msg.value >= 10 ether) {
                _deliverBlockedTokens(_beneficiary);
            }else {
                _deliverWhitelistedTokens(_beneficiary);
            }
        }else {
            _deliverTokens(_beneficiary);
        }
    }

    function _deliverTokens(address _beneficiary) internal{
      balances[_beneficiary] = balances[_beneficiary].add(msg.value);
      savedBalance = savedBalance.add(msg.value);
      savedTokenBalance = savedTokenBalance.add(msg.value.mul(rate));
      token.transfer(_beneficiary, msg.value.mul(rate));
      wallet.transfer(msg.value);
      emit PayEther(wallet, msg.value, now);
    }

    function _deliverWhitelistedTokens(address _beneficiary) internal{
      savedBalance = savedBalance.add(msg.value);
      uint256 tokensAmount = msg.value.mul(presaleRate);
      uint256 tokensToTransfer = tokensAmount.mul(130).div(100);
      savedTokenBalance = savedTokenBalance.add(tokensToTransfer);
      token.transfer(_beneficiary, tokensToTransfer);
      wallet.transfer(msg.value);
      emit PayEther(wallet, msg.value, now);
    }

    function _deliverBlockedTokens(address _beneficiary) internal {
      savedBalance = savedBalance.add(msg.value);
      uint256 tokensAmount = msg.value.mul(presaleRate);
      uint256 bonus = tokensAmount.mul(30).div(100);
      savedTokenBalance = savedTokenBalance.add(tokensAmount.add(bonus));
      token.transfer(_beneficiary, tokensAmount);
      savedBonusToken = savedBonusToken.add(bonus);
      bonusBalances[_beneficiary] = bonusBalances[_beneficiary].add(bonus);
      bonusList.push(_beneficiary);
      wallet.transfer(msg.value);
      emit PayEther(wallet, msg.value, now);
    }
}
