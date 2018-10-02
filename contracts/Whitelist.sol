pragma solidity ^0.4.24;

import "./Ownable.sol";

contract Whitelist is Ownable{

  // Whitelisted address
  mapping(address => bool) public whitelist;
  mapping(address => bool) public presalewhitelist;

  event AddedBeneficiary(address indexed _beneficiary);
  event AddedPresaleBeneficiary(address indexed _beneficiary);


  /* Presale section */
  function isPresaleWhitelisted(address _beneficiary) public view returns (bool) {
    return (presalewhitelist[_beneficiary]);
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToPresaleWhitelist(address[] _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      presalewhitelist[_beneficiaries[i]] = true;
      emit AddedPresaleBeneficiary(_beneficiaries[i]);
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromPresaleWhitelist(address _beneficiary) public onlyOwner {
    presalewhitelist[_beneficiary] = false;
  }

  /* Crowdsale section */

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
      emit AddedBeneficiary(_beneficiaries[i]);
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) public onlyOwner {
    whitelist[_beneficiary] = false;
  }

  function isWhitelisted(address _beneficiary) public view returns (bool) {
    return (whitelist[_beneficiary]);
  }

}
