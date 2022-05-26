const { assert } = require("chai");
const { ethers } = require("hardhat");

class Contracts {
  constructor(src, dst, bdg, _id) {
    this.source = new ethers.Contract(src);
    this.destination = new ethers.Contract(dst);
    this.bridge = new ethers.Contract(bdg);
    this.chain = _id;
  }

  connect(signer) {
    this.source.connect(signer);
    this.destination.connect(signer);
    this.bridge.connect(signer);
  }
}

const networks = {
  'opKovan':69, 'opMain':10,
  'arbRinkeby':421611, 'arbMain':42161,
  'bobaRinkeby':28, 'bobaMain':288
};

const CONTRACT_FEE_BASIS_POINTS = 5;
const CONTRACT_FEE_RAMPUP = 30;

let network = process.argv[2];
assert(network in networks.keys(), "Invalid network name supplied");

const contracts = new Contracts(
  process.argv[3], // BuddleSource
  process.argv[4], // BuddleDestination
  process.argv[5], // BuddleBridge
  networks[network]
);

const wallet = new ethers.Wallet(process.env.PRIVATE_KEY);
contracts.connect(wallet);