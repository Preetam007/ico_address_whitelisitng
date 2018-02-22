"use strict"

const Web3 = require('web3')
const express = require('express')
const http = require('http');
const fs = require('fs');
const coder = require('web3/lib/solidity/coder');  
const CryptoJS = require('crypto-js');

const app = express(); 

const bodyParser = require('body-parser');
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded b

const web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/<enter your key>"));
const obj = JSON.parse(fs.readFileSync('./build/contracts/ICOWHITELIST.json', 'utf8'));
const abiArray = obj.abi;
// icowhitelist contract address rinkbey testnet
const contractAddress = '0x0AC0F8fD8f546c4C189B2776209f2bfB7B0fc09C';
const whiteListContract =  web3.eth.contract(abiArray).at(contractAddress);
// add account address
const account = '';
const adminPass = '';
// add private key
const myPrivateKey = '';

 
var privateKey = new Buffer(myPrivateKey, 'hex') 

const Tx = require('ethereumjs-tx');

app.get('/totalWhitelisted',function countwhitelisted(req,res) {
  const total = whiteListContract.whitelistedInvestorsCount.call();
  res.send(total);
})


app.post('/whitelist', function (req, res) {
    
    // infura doesn't support eth_sendTransaction. We don't host private keys and therefore can't sign a txn. You'll need to use eth_sendRawTransaction after signing the transaction on your side.
    //eth_sendRawTransaction

    //@TODO - req.body.addresss

    const functionName = 'whiteListAddresses';
    const types = ['address[]'];  
    const args = [['0xF24725B2aA755057Aa9cDc670b5ffC802688cB6e']];  //@idea:  replace req.body.addresss
    const fullName = functionName + '(' + types.join() + ')';
    const signature = CryptoJS.SHA3(fullName,{outputLength:256}).toString(CryptoJS.enc.Hex).slice(0, 8);
    const dataHex = signature + coder.encodeParams(types, args);
    const data = '0x'+dataHex;  

    const nonce = web3.toHex(web3.eth.getTransactionCount(account));
    const gasPrice = web3.toHex(web3.eth.gasPrice);
    const gasLimitHex = web3.toHex(600000);
    const rawTx = { 'nonce': nonce, 'gasPrice': gasPrice, 'gasLimit': gasLimitHex, 'from': account, 'to': contractAddress,data : data};  
    const tx = new Tx(rawTx);
    tx.sign(privateKey);
    const serializedTx = '0x'+tx.serialize().toString('hex');
    web3.eth.sendRawTransaction(serializedTx, function(err, txHash) {
        console.log(err, txHash); 
        if (err) { return res.send ({'error' : err})};
        res.send('https://rinkeby.etherscan.io/tx/'+txHash);
    });    

    
});

app.get('/balance/:id', function (req, res) {
  const balance = web3.eth.getBalance(req.params.id).toNumber();
  const balanceInEth = balance / 1000000000000000000;
  res.send(balanceInEth);
})

app.get('/', function (req, res) {
  res.send('Welcome to API. Specs can be found: ');
})

var server = http.createServer(app);

server.listen(3000, function () {
  console.log('Example app listening on port 3000!')
})
