const poseidonGen = require("circomlibjs").poseidonContract.createCode;
const poseidonAbi = require("circomlibjs").poseidonContract.generateABI;
const fs = require("fs");

fs.writeFile(
    "pos", poseidonGen(2), (err) => {

    }
)

// fs.writeFile(
//     "pos.abi", poseidonAbi(2), (err) => {

//     }
// )

console.log(poseidonAbi(2));