var Token = artifacts.require("./LoligoToken.sol");
var Crowdsale = artifacts.require("./Crowdsale.sol");

module.exports = function(deployer, network) {
  const deployContracts = async (deployer, accounts) => {
  try {
      const token = await deployer.deploy(Token);
      const crowdsale = await deployer.deploy(Crowdsale, token.address);


      /* transfer ownership to crowdsale */
      await token.transferOwnership(crowdsale.address);

      /* deployed contracts */
      console.log('>>>>>>> Deployed contracts >>>>>>>>');
      console.log('Token contract at '+ token.address);
      console.log('Crowdsale contract at ' + crowdsale.address);
      console.log('Token new owner is'+ await token.owner.call());

      return true
  } catch (err) {
      console.log('### error deploying contracts', err)
  }
}
};
