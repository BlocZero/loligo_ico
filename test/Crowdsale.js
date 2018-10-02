import assertRevert from './helpers/assertRevert';
import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const Token = artifacts.require('./LoligoToken.sol');
const Crowdsale = artifacts.require('./Crowdsale.sol');

/* CONST FOR TESTS */
const TOKENSFORTEAM = 480000000000000000000000;
const TOKENSFORBOUNTY = 480000000000000000000000;
const TOKENSFORADVISORS = 1440000000000000000000000;

const ADDR_WALLET = web3.eth.accounts[9];
const ADDR_TEAM = web3.eth.accounts[8];
const ADDR_BOUNTY = web3.eth.accounts[7];
const ADDR_ADVISORS = web3.eth.accounts[6];

const TOTAL_SUPPLY =  16000000000000000000000000;
const TOKENSFORPRESALE = 11200000000000000000000000;

contract('Crowdsale', function ([owner, project, anotherAccount, user1, user2]) {
  let token;
  let crowdsale;

  beforeEach('redeploy', async function () {
    token = await Token.new({from : owner});
    crowdsale = await Crowdsale.new(token.address, {from : owner});

    await token.transfer(crowdsale.address, TOTAL_SUPPLY, {from : owner});
    await token.transferOwnership(crowdsale.address, {from : owner});
    await crowdsale.addManyToPresaleWhitelist([user1], {from : owner});
    await crowdsale.addManyToWhitelist([user2], {from : owner});

  });

  describe('Transfer ownership token to crowdsale', function () {
    it('return the same address', async function () {
      assert.equal(await token.owner.call(), crowdsale.address);
    });
  });

  describe('Test presale period', function () {
    it('presale period1 is not starting yet', async function(){
      assert.equal(await crowdsale.presale1.call(), false);
    });
    it('presale period2 is not starting yet', async function(){
      assert.equal(await crowdsale.presale2.call(), false);
    });
    it('rejects starting & setting params for presale period from another account', async function () {
      await assertRevert(crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : anotherAccount}));
    });
    it('starting presale period', async function () {
      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      assert.equal(await crowdsale.presale1.call(), true);
    });
    it('rejects starting presale period 2', async function () {
      await assertRevert(crowdsale.updatePresale({from : owner}));
    });
    it('rejects closing presale period from another account', async function () {
      await assertRevert(crowdsale.closePresale({from : anotherAccount}));
    });
    it('closing presale period', async function () {
      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      await crowdsale.updatePresale({from : owner});
      await crowdsale.closePresale({from : owner});
    });
  });

  describe('Test purchase on presale period', function(){
    it('rejects a contribution made when presale not yet starting', async function(){
      const paymentAmount = web3.toWei('1', 'ether');
      assert.equal(await crowdsale.presale1.call(), false);
      await assertRevert(crowdsale.sendTransaction( { from: user1 , value: paymentAmount }));
    });
    it('rejects closing presale from another account', async function(){
      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      assert.equal(await crowdsale.presale1.call(), true);
      await assertRevert(crowdsale.closePresale({from: anotherAccount}));
    });
    it('accepts closing presale from owner', async function(){
      await crowdsale.startPresale(10, TOKENSFORPRESALE,web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      assert.equal(await crowdsale.presale1.call(), true);
      await crowdsale.updatePresale({from: owner});
      await crowdsale.closePresale({from: owner});
      assert.equal(await crowdsale.presale1.call(), false);
      assert.equal(await crowdsale.presale2.call(), false);
    });
    it('rejects a contribution made from not whitelisted account', async function(){
      const paymentAmount = web3.toWei('3', 'ether');
      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      assert.equal(await crowdsale.presale1.call(), true);
      await assertRevert(crowdsale.sendTransaction( { from: anotherAccount , value: paymentAmount }));
    });
    it('accepts a contribution, during presale period 1, from whitelisted account and check token amount', async function(){
      const paymentAmount = web3.toWei('3', 'ether');

      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      assert.equal(await crowdsale.presale1.call(), true);

      assert.equal(await crowdsale.isPresaleWhitelisted.call(user1), true);

      await crowdsale.sendTransaction( { from: user1, value: paymentAmount });

      const tokensAmount = paymentAmount * 10;
      const balance = tokensAmount * 1.4;

      assert.equal(await token.balanceOf(user1).valueOf(), balance.valueOf());
    });
    it('accepts a contribution, during presale period 2, from whitelisted account and check token amount', async function(){
      const paymentAmount = web3.toWei('3', 'ether');

      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      await crowdsale.updatePresale({from: owner});
      assert.equal(await crowdsale.presale2.call(), true);
      assert.equal(await crowdsale.isPresaleWhitelisted.call(user1), true);

      await crowdsale.sendTransaction( { from: user1, value: paymentAmount });

      const tokensAmount = paymentAmount * 10;
      const balance = tokensAmount * 1.3;

      assert.equal(await token.balanceOf(user1).valueOf(), balance.valueOf());
    });
    it('accepts a contribution from whitelisted account and check token amount (no bunus when less than 1 ETH)', async function(){
      const paymentAmount = web3.toWei('0.5', 'ether');

      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      await crowdsale.updatePresale({from: owner});
      assert.equal(await crowdsale.presale2.call(), true);
      assert.equal(await crowdsale.isPresaleWhitelisted.call(user1), true);

      await crowdsale.sendTransaction( { from: user1, value: paymentAmount });

      const balance = paymentAmount * 10;

      assert.equal(await token.balanceOf(user1).valueOf(), balance.valueOf());
    });
    it('accepts a contribution, during presale period 1, from whitelisted account, check token amount & block the bonus when contribution value >= 10 ether', async function(){
      const paymentAmount = web3.toWei('10', 'ether');

      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether') , {from : owner});
      assert.equal(await crowdsale.presale1.call(), true);

      assert.equal(await crowdsale.isPresaleWhitelisted.call(user1), true);

      await crowdsale.sendTransaction( { from: user1, value: paymentAmount });

      const balance = paymentAmount * 10;
      const bonus = balance * 0.4;

      assert.equal(await token.balanceOf(user1).valueOf(), balance.valueOf());
      assert.equal(await crowdsale.bonusBalances.call(user1), bonus.valueOf());
    });
    it('accepts a contribution, during presale period 2, from whitelisted account, check token amount & block the bonus when contribution value >= 10 ether', async function(){
      const paymentAmount = web3.toWei('10', 'ether');

      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether') , {from : owner});
      await crowdsale.updatePresale({from: owner});
      assert.equal(await crowdsale.presale2.call(), true);

      assert.equal(await crowdsale.isPresaleWhitelisted.call(user1), true);

      await crowdsale.sendTransaction( { from: user1, value: paymentAmount });

      const balance = paymentAmount * 10;
      const bonus = balance * 0.3;

      assert.equal(await token.balanceOf(user1).valueOf(), balance.valueOf());
      assert.equal(await crowdsale.bonusBalances.call(user1), bonus.valueOf());
    });
  });

  describe('Test Crowdsale period', function () {
    beforeEach('set params for crowdsale period', async function () {
      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
    });
    it('crowdsale period is not starting yet', async function(){
      assert.equal(await crowdsale.crowdsale.call(), false);
    });
    it('starting crowdsale period', async function () {
      assert.equal(await crowdsale.crowdsale.call(), false);
      await crowdsale.closePresale({from : owner});
      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
      assert.equal(await crowdsale.crowdsale.call(), true);
    });
    it('rejects finalizing crowdsale from another account', async function () {
      await assertRevert(crowdsale.finalize({from : anotherAccount}));
    });
    it('rejects finalizing crowdsale during the presale period', async function () {
      await assertRevert(crowdsale.finalize({from : owner}));
    });
    it('accepts finalizing crowdsale during the crowdsale period', async function () {
      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      await crowdsale.finalize({from : owner});
      assert.equal(await crowdsale.crowdsale.call(), false);
    });
  });

  describe('Test purchase on crowdsale period', function(){
    beforeEach('setParams', async function () {
      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      await crowdsale.closePresale({from : owner});
    });
    it('rejects a contribution made when crowdsale not yet starting', async function(){
      const paymentAmount = web3.toWei('1', 'ether');
      await assertRevert(crowdsale.sendTransaction( { from: anotherAccount , value: paymentAmount }));
    });
    it('rejects contribution when the maxCap is raised', async function () {
      const paymentAmount = web3.toWei('10', 'ether');

      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
      assert.equal(await crowdsale.crowdsale.call(), true);

      await crowdsale.sendTransaction( { from: user1, value: paymentAmount });
      await assertRevert(crowdsale.sendTransaction( { from: user1, value:  paymentAmount}));
    });
    it('accepts a contribution', async function(){
      const paymentAmount = web3.toWei('3', 'ether');

      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
      assert.equal(await crowdsale.crowdsale.call(), true);

      await crowdsale.sendTransaction( { from: user1, value: paymentAmount });
    });
    it('accepts contribution and check amount tokens after a purchase', async function(){
      const paymentAmount = web3.toWei('5', 'ether');

      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
      assert.equal(await crowdsale.crowdsale.call(), true);

      await crowdsale.sendTransaction( { from: anotherAccount, value: paymentAmount });

      const balance = paymentAmount * 10;
      assert.equal(await token.balanceOf(anotherAccount), balance.valueOf());
    });
    it('accepts purchase from whitelisted account and check the tokens amount sent', async function(){
      const paymentAmount = web3.toWei('6', 'ether');

      assert.equal(await crowdsale.isWhitelisted.call(user2), true);

      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
      assert.equal(await crowdsale.crowdsale.call(), true);

      await crowdsale.sendTransaction( { from: user2, value: paymentAmount });

      const tokensAmount = paymentAmount * 10;
      const balance = tokensAmount * 1.3;
      assert.equal(await token.balanceOf(user2), balance.valueOf());
    });
    it('accepts contribution from a whitelisted account check token amount & block the bonus when contribution value >= 10 ether', async function () {
      const paymentAmount = web3.toWei('10', 'ether');

      assert.equal(await crowdsale.isWhitelisted.call(user2), true);

      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
      assert.equal(await crowdsale.crowdsale.call(), true);

      await crowdsale.sendTransaction( { from: user2, value: paymentAmount });
      const balance = paymentAmount * 10;
      const bonus = balance * 0.3;

      assert.equal(await token.balanceOf(user2), balance.valueOf());
      assert.equal(await crowdsale.bonusBalances.call(user2), bonus.valueOf());
    });
  });

  describe('Test distribution of the blocked bonus token', function(){
    beforeEach('setParams', async function () {
      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      await crowdsale.closePresale({from : owner});
      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
    });
    it('accepts a contribution from whitelisted account, check token amount, block the bonus & distribute the bonus by the owner', async function(){
      const paymentAmount = web3.toWei('10', 'ether');

      assert.equal(await crowdsale.crowdsale.call(), true);
      assert.equal(await crowdsale.isWhitelisted.call(user2), true);

      await crowdsale.sendTransaction( { from: user2, value: paymentAmount });

      const balance = paymentAmount * 10;
      const bonus = balance * 0.3;

      assert.equal(await token.balanceOf(user2).valueOf(), balance.valueOf());
      assert.equal(await crowdsale.bonusBalances.call(user2), bonus.valueOf());


      var actualBalance = await token.balanceOf(user2);
      await crowdsale.distributeBonusToken(token.address, 100, {from : owner});
      var newBalance = await token.balanceOf(user2);

      assert.equal(actualBalance.add(bonus).valueOf(), newBalance.valueOf());
    });
  });

  describe('Test refund period', function(){
    beforeEach('setParams', async function () {
       await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
    });
    it('rejects a refund when refund period is not started', async function(){
      const paymentAmount = web3.toWei('1', 'ether');

      assert.equal(await crowdsale.crowdsale.call(), true);
      await crowdsale.sendTransaction( { from: anotherAccount , value: paymentAmount });
      await assertRevert(crowdsale.refund({from : anotherAccount}));
    });
    it('accepts refund and check the refunded amount', async function(){
      const paymentAmount = web3.toWei('1', 'ether');

      await crowdsale.sendTransaction( { from: anotherAccount, value: paymentAmount });
      await crowdsale.closeCrowdsale({from : owner});
      await increaseTimeTo(latestTime());

      var actualBalance = web3.fromWei(web3.eth.getBalance(anotherAccount),'ether');

      await crowdsale.sendTransaction( { from: ADDR_WALLET, to: crowdsale.address, value: paymentAmount });
      await crowdsale.refund({from : anotherAccount, gasPrice: 0 });
      await crowdsale.withdraw({from : anotherAccount, gasPrice: 0 });

      const amountToRefund = paymentAmount * 0.95;
      const newBalance = actualBalance.add(web3.fromWei(amountToRefund, 'ether'));
      actualBalance = web3.fromWei(web3.eth.getBalance(anotherAccount), 'ether');
      assert.equal(actualBalance.valueOf(), newBalance.valueOf());
    });
    it('rejects a refund from a none contributor', async function(){
      await assertRevert(crowdsale.refund({from : anotherAccount}));
    });
  });

  describe('Test payout', function(){
    beforeEach('setParams', async function () {
      await crowdsale.startPresale(10, TOKENSFORPRESALE, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from : owner});
      await crowdsale.closePresale({from : owner});
      await crowdsale.startCrowdsale(10, web3.toWei('10', 'ether'), web3.toWei('2', 'ether'), {from: owner});
    });
    it('When ico is successful', async function(){
      const paymentAmount = web3.toWei('10', 'ether');
      var actualBalance = await web3.eth.getBalance(ADDR_WALLET);

      assert.equal(await crowdsale.presale2.call(), false);
      assert.equal(await crowdsale.crowdsale.call(), true);
      await crowdsale.sendTransaction( { from: anotherAccount , value: paymentAmount });

      await crowdsale.payout(user1,{from : owner});

      assert.equal(await token.balanceOf(ADDR_TEAM).valueOf(), TOKENSFORTEAM);
      assert.equal(await token.balanceOf(ADDR_BOUNTY).valueOf(), TOKENSFORBOUNTY);
      assert.equal(await token.balanceOf(ADDR_ADVISORS).valueOf(), TOKENSFORADVISORS);

      assert.equal(await token.owner.call(), user1);
      assert.equal(await crowdsale.crowdsale.call(), false);
      assert.equal(await web3.eth.getBalance(crowdsale.address), 0);
      var newBalance = actualBalance.add(paymentAmount);
      assert.equal(await web3.eth.getBalance(ADDR_WALLET).valueOf(), newBalance.valueOf());
    });
    it('rejects transaction, when ico is successful, from another account', async function(){
      const paymentAmount = web3.toWei('10', 'ether');

      await crowdsale.sendTransaction( { from: anotherAccount , value: paymentAmount });
      await assertRevert(crowdsale.payout(user1, {from : anotherAccount}));
    });
    it('rejects payout when ico is not successful and refund period is not yet finished', async function(){
      const paymentAmount = web3.toWei('1', 'ether');

      await crowdsale.sendTransaction( { from: anotherAccount , value: paymentAmount });
      await crowdsale.closeCrowdsale({from : owner});
      await assertRevert(crowdsale.payout(user1, {from : owner}));
    });
    it('payout when ico is not successful', async function(){
      const paymentAmount = web3.toWei('1', 'ether');
      var actualBalance = await web3.eth.getBalance(ADDR_WALLET);

      await crowdsale.sendTransaction( { from: anotherAccount , value: paymentAmount });
      await crowdsale.closeCrowdsale({from : owner});
      await increaseTimeTo(latestTime() + duration.days(31));
      await crowdsale.payout(user1, {from : owner});

      assert.equal(web3.eth.getBalance(crowdsale.address), 0);
      var newBalance = actualBalance.add(paymentAmount);
      assert.equal(await web3.eth.getBalance(ADDR_WALLET).valueOf(), newBalance.valueOf());
      assert.equal(await token.owner.call(), user1);
      assert.equal(await token.balanceOf(crowdsale.address), 0);
    });
  });

});
