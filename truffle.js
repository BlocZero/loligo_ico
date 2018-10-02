/*
 * NB: since truffle-hdwallet-provider 0.0.5 you must wrap HDWallet providers in a
 * function when declaring them. Failure to do so will cause commands to hang. ex:
 * ```
 * mainnet: {
 *     provider: function() {
 *       return new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/<infura-key>')
 *     },
 *     network_id: '1',
 *     gas: 4500000,
 *     gasPrice: 10000000000,
 *   },
 */
 var HDWalletProvider = require("truffle-hdwallet-provider");
 var mnemonic = "door sadness shallow hire fame lesson wonder scan donate caution apple chicken"; //new mnemonic to generate

 // Allows us to use ES6 in our migrations and tests.
 require('babel-register')({
   ignore: /node_modules\/(?!test\/helpers)/
 });
 require('babel-polyfill');
 module.exports = {
   networks: {
     mainnet: {
       provider:  function() {
         return new HDWalletProvider(mnemonic, "https://mainnet.infura.io/M61bTRVBOvpealSVYTxe") //infura key to generate
       },
       network_id: 1
     },
     ropsten: {
       provider: function() {
         return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/M61bTRVBOvpealSVYTxe") //infura key to generate
       },
       network_id: 3,
       gas: 4712388
     },
     ganache: {
      host: "localhost",
      port: 7545,
      network_id: "*",
      gas: 4712388
    },
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*"
    }
   },
   rpc: {
         host: 'localhost',
         post:8080
    },
   optimizer: {
     enabled: false
   }
 };
