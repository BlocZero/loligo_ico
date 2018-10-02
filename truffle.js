// Allows us to use ES6 in our migrations and tests.
require('babel-register')({
  ignore: /node_modules\/(?!test\/helpers)/
});
require('babel-polyfill');
const HDWalletProvider = require("truffle-hdwallet-provider");

 // Infura API key
const infura_apikey_dev = process.env.DSLA_INFURA_APIKEY_DEV;
const infura_apikey_prod = process.env.DSLA_INFURA_APIKEY_PROD;

// 12 mnemonic words that represents the account that will own the contract
const mnemonic_dev = process.env.DSLA_MNEMONIC_DEV;
const mnemonic_prod = process.env.DSLA_MNEMONIC_PROD;

 module.exports = {
   networks: {
   development: {
     host: "localhost",
     port: 8545,
     network_id: "*", // Match any network id
   },
   ropsten: {
     provider: function() {
       return new HDWalletProvider(mnemonic_dev, "https://ropsten.infura.io/v3/" + infura_apikey_dev);
     },
     network_id: "3",
     gas: 4612388
   },
   mainnet: {
     provider: function() {
       return new HDWalletProvider(mnemonic_prod, "https://mainnet.infura.io/v3/" + infura_apikey_prod);
     },
     network_id: "1",
     gas: 4612388
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
