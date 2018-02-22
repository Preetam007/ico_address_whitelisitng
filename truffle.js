// var HDWalletProvider = require("truffle-hdwallet-provider");
// var mnemonic = "myway$1A";


// Allows us to use ES6 in our migrations and tests.
require('babel-register')
var bip39 = require("bip39");
var hdkey = require('ethereumjs-wallet/hdkey');
var ProviderEngine = require("web3-provider-engine");
var WalletSubprovider = require('web3-provider-engine/subproviders/wallet.js');
var Web3Subprovider = require("web3-provider-engine/subproviders/web3.js");
var Web3 = require("web3");

// Get our mnemonic and create an hdwallet
var mnemonic = "CHANGE ME aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll";
var hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(mnemonic));

// Get the first account using the standard hd path.
var wallet_hdpath = "m/44'/60'/0'/0/";
var wallet = hdwallet.derivePath(wallet_hdpath + "0").getWallet();
var address = "0x" + wallet.getAddress().toString("hex");

console.log(address);

var providerUrl = "https://ropsten.infura.io/bcojZFdgTHPc8qdQGN3D";
var engine = new ProviderEngine();
engine.addProvider(new WalletSubprovider(wallet, {}));
engine.addProvider(new Web3Subprovider(new Web3.providers.HttpProvider(providerUrl)));

// log new blocks
engine.on('block', function(block){
  console.log('================================')
  console.log('BLOCK CHANGED:', '#'+block.number.toString('hex'), '0x'+block.hash.toString('hex'))
  console.log('================================')
})

// network connectivity error
engine.on('error', function(err){
  // report connectivity errors
  console.error(err.stack)
})


engine.start(); // Required by the provider engine.

/*
  In order to transact with Infura nodes, you will need to create and sign transactions 
  offline before sending them, as Infura nodes have no visibility of your encrypted Ethereum key 
  files, which are required to unlock accounts via the Personal Geth/Parity admin commands.
*/

// truffle compile

//geth --rinkeby --rpc --rpcapi db,eth,net,web3,personal --unlock="0x6a6401AEb4a3beb93820904E761b0d86364bb39E" --rpccorsdomain http://localhost:3000

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    // truffle migrate --network development
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    // geth --fast --cache=1048 --testnet --unlock "0xmyaddress" --rpc --rpcapi "eth,net,web3" --rpccorsdomain '*' --rpcaddr localhost --rpcport 8545
    // ropsten: {
    //   host: "localhost",
    //   port: 8545,
    //   network_id: "3"
    // },
    ropsten: {
      network_id: 3,    // Official ropsten network id
      provider: engine, // Use our custom provider
      from: address,     // Use the address we derived
      gas: 3000000
    },
    //truffle migrate --network ropsten
    // ropsten: {
    //   provider: function() {
    //     return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/bcojZFdgTHPc8qdQGN3D")
    //   },
    //   network_id: 3
    // },
    // truffle migrate --network rinkeby
    rinkeby: {
      host: "localhost", // Connect to geth on the specified
      port: 8545,
      from: "0x0085f8e72391Ce4BB5ce47541C846d059399fA6c", // default address to use for any transaction Truffle makes during migrations
      network_id: 4,
      gas: 4612388 // Gas limit used for deploys
    }   
  }
};
