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

    // addresses for the token distribution

    // addresses for testing to change 
    address private wallet = 0x94c921261EA20Ef9Bab3600528A29fEC0913eDf7;
    address private team = 0x19eB1f08033ecffa1c72932bFDac5EE5994EA619;
    address private advisors = 0x2fA93B985cD88B7E0E5402C4823B3eee9BA50428;
    address private bounty = 0x494c857Fd14F862DE562B0D8A95dac295334D866;

    // LLG token
    LoligoToken public token;

    // Presale period
    uint256 public presaleRate;                                          // Rate presale LLG token per ether
    uint256 public totalTokensForPresale;                                // LLG tokens allocated for the Presale
    bool public presale1;                                                // Presale first period
    bool public presale2;                                                // Presale second period

    // Crowdsale period
    uint256 public rate;                                                 // Rate LLG token per ether
    uint256 public totalTokensForSale = 11200000000000000000000000;      // 11 200 000 LLG tokens will be sold in Crowdsale
    uint256 public  maxFundingGoal;                                      // Maximum goal in Ether raised
    uint256 public  minFundingGoal;                                      // Minimum funding goal in Ether raised
    bool public crowdsale;                                               // Crowdsale period

    // Refund Period
    uint256 public  REFUNDSTART;                                        // epoch timestamp representing the refundPeriodStart date of refund period
    uint256 public  REFUNDEADLINE;                                      // epoch timestamp representing the end date of refund period

    // Allocated tokens for team, bounty & advisors
    uint256 public tokensForTeam = 480000000000000000000000;
    uint256 public tokensForBounty = 480000000000000000000000;
    uint256 public tokensForAdvisors = 1440000000000000000000000;

    // Sales params
    uint256 public savedBalance;                                        // Total amount raised in ETH
    uint256 public savedTokenBalance;                                   // Total sold tokens for presale
    uint256 public savedPresaleTokenBalance;                            // Total sold tokens for crowdsale
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
          require(presale1 || presale2 || crowdsale);
          if (presale1 || presale2) {
              buyPresaleTokens(msg.sender);
          }else{
              buyTokens(msg.sender);
          }
        }
    }

    /***********************************
    *       Public functions for the   *
    *           Presale period         *
    ************************************/

    // Function to set Rate & tokens to sell for presale (period1)
    function startPresale(uint256 _rate, uint256 _totalTokensForPresale, uint256 _maxCap, uint256 _minCap) public onlyOwner {
        presaleRate = _rate;
        totalTokensForPresale = _totalTokensForPresale;
        maxFundingGoal = _maxCap;
        minFundingGoal = _minCap;
        presale1 = true;
    }

    // Function to move to the second period for presale (period2)
    function updatePresale() public onlyOwner {
        require(presale1);
        presale1 = false;
        presale2 = true;
    }

    // Function to close the presale period2
    function closePresale() public onlyOwner {
        require(presale2 || presale1);
        presale1 = false;
        presale2 = false;
    }

    /***********************************
    *       Public functions for the   *
    *           Crowdsale period       *
    ************************************/

    // Function to start crowdsale period & set up params
    function startCrowdsale(uint256 _rate, uint256 _maxCap, uint256 _minCap) public onlyOwner {
        require(!presale2 || !presale1);
        rate = _rate;
        maxFundingGoal = _maxCap;
        minFundingGoal = _minCap;
        crowdsale = true;
    }

    // Function to close the crowdsale period
    function closeCrowdsale() public onlyOwner{
      require(crowdsale);
	    crowdsale = false;
      REFUNDSTART = now;
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
        return (now > REFUNDEADLINE);
    }

    // Function to check the refund period is over
    function refundPeriodStart() public view returns (bool) {
        return (now > REFUNDSTART);
    }

    // Only owner will finalize the crowdsale
    function finalize() public onlyOwner {
        require(crowdsale);
        crowdsale = false;
        REFUNDSTART = now;
        REFUNDEADLINE = REFUNDSTART+ 30 days;
    }

    // Function to pay out
    function payout(address _newOwner) public onlyOwner {
        require((isSuccessful() && isComplete()) || refundPeriodOver());
        if (isSuccessful() && isComplete()) {
            require(token.transfer(team, tokensForTeam));
            require(token.transfer(bounty, tokensForBounty));
            require(token.transfer(advisors, tokensForAdvisors));
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
        asyncSend(msg.sender, amountToRefund);
        balances[msg.sender] = 0;
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
    function buyTokens(address _beneficiary) internal {
        require(!isComplete());

        if (isWhitelisted(_beneficiary)) {
            uint256 tokensAmount;
            if (msg.value >= 10 ether) {
                savedBalance = savedBalance.add(msg.value);
                tokensAmount = msg.value.mul(presaleRate);
                uint256 bonus = tokensAmount.mul(30).div(100);
                savedTokenBalance = savedTokenBalance.add(tokensAmount.add(bonus));
                token.transfer(_beneficiary, tokensAmount);
                savedBonusToken = savedBonusToken.add(bonus);
                bonusBalances[_beneficiary] = bonusBalances[_beneficiary].add(bonus);
                bonusList.push(_beneficiary);
                wallet.transfer(msg.value);
                emit PayEther(wallet, msg.value, now);
            }else {
                savedBalance = savedBalance.add(msg.value);
                tokensAmount = msg.value.mul(presaleRate);
                uint256 tokensToTransfer = tokensAmount.mul(130).div(100);
                savedTokenBalance = savedTokenBalance.add(tokensToTransfer);
                token.transfer(_beneficiary, tokensToTransfer);
                wallet.transfer(msg.value);
                emit PayEther(wallet, msg.value, now);
            }
        }else {
            balances[_beneficiary] = balances[_beneficiary].add(msg.value);
            savedBalance = savedBalance.add(msg.value);
            savedTokenBalance = savedTokenBalance.add(msg.value.mul(rate));
            token.transfer(_beneficiary, msg.value.mul(rate));
            wallet.transfer(msg.value);
            emit PayEther(wallet, msg.value, now);
        }
    }

    function buyPresaleTokens(address _beneficiary) internal {
        require(isPresaleWhitelisted(_beneficiary));
        require((savedBalance.add(msg.value)) <= maxFundingGoal);
        require((savedPresaleTokenBalance.add(msg.value.mul(presaleRate))) <= totalTokensForPresale);
        uint256 tokensAmount;

        if (msg.value >= 10 ether) {
            savedBalance = savedBalance.add(msg.value);
            tokensAmount = msg.value.mul(presaleRate);
            uint256 bonus = tokensAmount.mul(checkPresaleBonus()).div(100);
            savedTokenBalance = savedTokenBalance.add(tokensAmount.add(bonus));
            token.transfer(_beneficiary, tokensAmount);
            savedBonusToken = savedBonusToken.add(bonus);
            bonusBalances[_beneficiary] = bonusBalances[_beneficiary].add(bonus);
            bonusList.push(_beneficiary);
            wallet.transfer(msg.value);
            emit PayEther(wallet, msg.value, now);
        }else {
            savedBalance = savedBalance.add(msg.value);
            tokensAmount = msg.value.mul(presaleRate);
            uint256 tokensToTransfer = tokensAmount.add((tokensAmount.mul(checkPresaleBonus())).div(100));
            savedTokenBalance = savedTokenBalance.add(tokensToTransfer);
            token.transfer(_beneficiary, tokensToTransfer);
            wallet.transfer(msg.value);
            emit PayEther(wallet, msg.value, now);
        }
    }

    function checkPresaleBonus() internal view returns (uint256){
        if(presale1 && msg.value >= 1 ether){
          return 40;
        }else if(presale2 && msg.value >= 1 ether){
          return 30;
        }else{
          return 0;
        }
    }
}
