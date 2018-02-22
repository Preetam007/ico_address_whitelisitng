'use strict';

// need local geth or unlocked account

const fs = require('fs');
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8549'));

var obj = JSON.parse(fs.readFileSync('./../build/contracts/ICOWHITELIST', 'utf8'));
var abiArray = obj.abi;
const ADDRESSES = require('./ADDRESSES')();
const adminAccount = '';
const whiteListContract = '';

const Addresses_per_tx = 120;
const slices = Math.ceil(ADDRESSES.length / Addresses_per_tx);

const myContract = new web3.eth.Contract(abiArray, whiteListContract, {
    from: adminAccount, // unlocked account from address
    gasPrice: '20000000000' // default gas price in wei ~20gwei
});

whitelist(slices).then(console.log);
function whitelist(slice) {
    const start = (slice - 1) * Addresses_per_tx;
    const end = (slice) * Addresses_per_tx;
    const proccessingArray = ADDRESSES.slice(start, end);
    console.log('processing:', proccessingArray);
    return new Promise((resolve, reject) => {
        myContract.methods.whiteListAddresses(proccessingArray).estimateGas().then((gasNeeded) => {
            myContract.methods.whiteListAddresses(proccessingArray).send({
                gas: gasNeeded
            }).then((receipt) => {
                slice--;
                console.log(receipt,slice);
                if (slice > 0) {
                    whitelist(slice);
                } else {
                    resolve('done');
                }
            })
        });
    })

}