const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

const optimism = require('./init/optimism');
const arbitrum = require('./init/arbitrum');
const boba = require('./init/boba');
const nitro = require('./init/nitro');

const version = 'v 0.2.0';

// process cmd args
let chain = process.argv[2];
chain = chain[0].toUpperCase() + chain.substring(1);
let network = process.argv[3];

// set ethers providers
let l1provider = null, l2provider = null;
switch(chain,network) {
  case ('Optimism','testnet'):
    l1provider = new ethers.providers.JsonRpcProvider(process.env.KOVAN_URL)
    l2provider = new ethers.providers.JsonRpcProvider(process.env.OPTIMISTIC_KOVAN_URL)
    break;
  case ('Arbitrum','testnet'): 
    l1provider = new ethers.providers.JsonRpcProvider(process.env.RINKEBY_URL)
    l2provider = new ethers.providers.JsonRpcProvider(process.env.ARBITRUM_RINKEBY_URL)
    break;
  case ('Boba','testnet'): 
    l1provider = new ethers.providers.JsonRpcProvider(process.env.RINKEBY_URL)
    l2provider = new ethers.providers.JsonRpcProvider(process.env.BOBA_RINKEBY_URL)
    break;
  case ('Nitro','testnet'): 
    l1provider = new ethers.providers.JsonRpcProvider(process.env.GOERLI_URL)
    l2provider = new ethers.providers.JsonRpcProvider(process.env.ARBITRUM_NITRO_URL)
    break;
  default: console.log('unsupported chain and network combination'); process.exitCode = 1;
}

// define l1 and l2 signer
const l1signer = new ethers.Wallet(process.env.PRIVATE_KEY, l1provider);
const l2signer = new ethers.Wallet(process.env.PRIVATE_KEY, l2provider);

// get contract addresses
const file = fs.readFileSync(`${__dirname}/deployed.json`, "utf-8");
const deployed = JSON.parse(file);
const addresses = {
  source: deployed[chain]['source']['address'],
  destination: deployed[chain]['destination']['address'],
  bridge: deployed[chain]['bridge']['address']
}

// get abis
const abi_dir = path.join(path.join(__dirname, '..', path.join('artifacts', 'contracts')));
const abis = {
  source: () => {
    const name = `BuddleSrc${chain}`;
    const file = fs.readFileSync(`${abi_dir}/${chain.toLowerCase()}/${name}.sol/${name}.json`);
    return JSON.parse(file)['abi']
  },
  destination: () => {
    const name = `BuddleDest${chain}`;
    const file = fs.readFileSync(`${abi_dir}/${chain.toLowerCase()}/${name}.sol/${name}.json`);
    return JSON.parse(file)['abi']
  },
  bridge: () => {
    const name = `BuddleBridge${chain}`;
    const file = fs.readFileSync(`${abi_dir}/${chain.toLowerCase()}/${name}.sol/${name}.json`);
    return JSON.parse(file)['abi']
  }
}

// connect to contracts
const contracts = {
  source: new ethers.Contract(addresses.source, abis.source(), l2signer),
  destination: new ethers.Contract(addresses.destination, abis.destination(), l2signer),
  bridge: new ethers.Contract(addresses.bridge, abis.bridge(), l1signer)
}

switch(chain) {
  case 'Optimism': optimism(version, contracts, deployed); break;
  case 'Arbitrum': arbitrum(version, contracts, deployed); break;
  case 'Boba': boba(version, contracts, deployed); break;
  case 'Nitro': nitro(version, contracts, deployed); break;
  default: console.log('unsupported chain'); process.exitCode = 1;
}

// console.log('Contracts initialized!');

// TODO : Add supported tokens