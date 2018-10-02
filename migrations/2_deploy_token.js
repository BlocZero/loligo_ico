var Token = artifacts.require("./LoligoToken.sol");

module.exports = function(deployer, network) {
  deployer.deploy(Token);
};
