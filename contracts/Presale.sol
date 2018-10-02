pragma solidity 0.4.24;


import "./SafeMath.sol";
import "./LoligoToken.sol";
import "./Pausable.sol";
import "./Whitelist.sol";
import "./TokenBonus.sol";


/*
*  Presale Smart Contract for the Loligo project
*  Author: Yosra Helal yosra.helal@bechainsc.com
*/



contract Presale is Pausable, Whitelist, TokenBonus {
    using SafeMath for uint256;

    // addresse for testing to change
    address private wallet = 0x94c921261EA20Ef9Bab3600528A29fEC0913eDf7;     // ETH wallet

    // LLG token
    LoligoToken public token;

    // Presale period
    uint256 public presaleRate;                                          // Rate presale LLG token per ether
    uint256 public totalTokensForPresale;                                // LLG tokens allocated for the Presale
    bool public presale1;                                                // Presale first period
    bool public presale2;                                                // Presale second period

    // presale params
    uint256 public savedBalance;                                        // Total amount raised in ETH
    uint256 public savedPresaleTokenBalance;                            // Total sold tokens for presale
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
        require(presale1 || presale2);
        _buyPresaleTokens(msg.sender);
    }

    /***********************************
    *       Public functions for the   *
    *           Presale period         *
    ************************************/

    // Function to set Rate & tokens to sell for presale (period1)
    function startPresale(uint256 _rate, uint256 _totalTokensForPresale) public onlyOwner {
        presaleRate = _rate;
        totalTokensForPresale = _totalTokensForPresale;
        presale1 = true;
    }

    // Function to move to the second period for presale (period2)
    function updatePresale() public onlyOwner {
        require(presale1);
        presale1 = false;
        presale2 = true;
    }

    // Function to close the presale period2
    function closePresale(address _crowdsale) public onlyOwner {
        require(presale2 || presale1);
        presale1 = false;
        presale2 = false;
        uint256 tokensToTransfer =  token.balanceOf(address(this)).sub(savedBonusToken);
        token.transfer(_crowdsale, tokensToTransfer);
    }

    // Function to transferOwnership of the LLG token
    function transferTokenOwnership(address _newOwner) public onlyOwner {
        token.transferOwnership(_newOwner);
    }

    /***************************************
    *          internal functions          *
    ****************************************/

    // Contribute Function, accepts incoming payments and tracks balances for each contributors
    function _buyPresaleTokens(address _beneficiary) internal {
        require(isWhitelisted(_beneficiary));
        require((savedPresaleTokenBalance.add(msg.value.mul(presaleRate))) <= totalTokensForPresale);

        if (msg.value >= 10 ether) {
          _deliverBlockedTokens(_beneficiary);
        }else {
          _deliverTokens(_beneficiary);
        }
    }

    function _deliverBlockedTokens(address _beneficiary) internal {
        uint256 tokensAmount = msg.value.mul(presaleRate);
        uint256 bonus = tokensAmount.mul(_checkPresaleBonus()).div(100);

        savedPresaleTokenBalance = savedPresaleTokenBalance.add(tokensAmount.add(bonus));
        token.transfer(_beneficiary, tokensAmount);
        savedBonusToken = savedBonusToken.add(bonus);
        bonusBalances[_beneficiary] = bonusBalances[_beneficiary].add(bonus);
        bonusList.push(_beneficiary);
        wallet.transfer(msg.value);
        emit PayEther(wallet, msg.value, now);
    }

    function _deliverTokens(address _beneficiary) internal {
      uint256 tokensAmount = msg.value.mul(presaleRate);
      uint256 tokensToTransfer = tokensAmount.add((tokensAmount.mul(_checkPresaleBonus())).div(100));

      savedPresaleTokenBalance = savedPresaleTokenBalance.add(tokensToTransfer);
      token.transfer(_beneficiary, tokensToTransfer);
      wallet.transfer(msg.value);
      emit PayEther(wallet, msg.value, now);
    }

    function _checkPresaleBonus() internal view returns (uint256){
        if(presale1 && msg.value >= 1 ether){
          return 40;
        }else if(presale2 && msg.value >= 1 ether){
          return 30;
        }else{
          return 0;
        }
    }
}
