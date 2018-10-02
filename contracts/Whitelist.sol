pragma solidity ^0.4.24;

import "./Ownable.sol";

contract Whitelist is Ownable{

  // Whitelisted address
  mapping(address => bool) public whitelist;
  // evants
  event LogAddedBeneficiary(address indexed _beneficiary);
  event LogRemovedBeneficiary(address indexed _beneficiary);

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) public onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
      emit LogAddedBeneficiary(_beneficiaries[i]);
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) public onlyOwner {
    whitelist[_beneficiary] = false;
    emit LogRemovedBeneficiary(_beneficiaries);
  }

  function isWhitelisted(address _beneficiary) public view returns (bool) {
    return (whitelist[_beneficiary]);
  }

}
