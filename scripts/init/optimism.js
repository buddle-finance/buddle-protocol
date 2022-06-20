const { ethers } = require("hardhat");
const fs = require("fs");

const consts = require('./consts.js');
const extractData = require("./utils.js");

// TODO : Add try-catch for each function call

async function initiailizeSrc(contract, version, bridge, data) {

  let w_data = {}

  // call initialize(...)
  console.log('Calling `initialize(...)` on source contract. Waiting for 3 confirmations..');
  let init_tx = await contract.initialize(
    version,
    consts.CONTRACT_FEE_BASIS_POINTS,
    consts.CONTRACT_FEE_RAMPUP,
    bridge,
    consts.callOptions
  ); init_tx = init_tx.wait(3);
  w_data.initialize = extractData(init_tx);
  w_data.initialize.inputs = {
    '_version': version,
    '_feeBasisPoints': consts.CONTRACT_FEE_BASIS_POINTS,
    '_feeRampUp': consts.CONTRACT_FEE_RAMPUP,
    '_buddleBridge': bridge
  };

  // call setXDomainMessenger(...)
  console.log('Calling `setXDomainMessenger(...)` and waiting for 3 confirmations..');
  let xdomain_tx = await contract.setXDomainMessenger(
    '0x4200000000000000000000000000000000000007',
    '0x4200000000000000000000000000000000000010',
    consts.callOptions
  ); xdomain_tx = xdomain_tx.wait(3);
  w_data.setXDomainMessenger = extractData(xdomain_tx);
  w_data.setXDomainMessenger.inputs = {
    '_messenger': '0x4200000000000000000000000000000000000007',
    '_stdBridge': '0x4200000000000000000000000000000000000010'
  }

  // call addDestination(...)
  for (item of data) {
    console.log(`Calling \`addDestination(...)\` with chain ${item.chain} and waiting for 3 confirmations..`);
    let dest_tx = await contract.addDestination(
      item.chain,
      item.destination,
      consts.callOptions
    ); dest_tx = dest_tx.wait(3);
    w_data.addDestination = extractData(dest_tx);
    w_data.addDestination.inputs = {
      '_chain': item.chain,
      '_contract': item.destination
    }
  }

  console.log('Initialized source contract\n')

  return w_data;
}

async function initiailizeDest(contract, version, bridge) {

  let w_data = {};

  // call initialize(...)
  console.log('Calling `initialize(...) on destination contract. Waiting for 3 confirmations..');
  let init_tx = await contract.initialize(
    version,
    bridge,
    consts.callOptions
  ); init_tx = init_tx.wait(3);
  w_data.initialize = extractData(init_tx);
  w_data.initialize.inputs = {
    '_version': version,
    '_buddleBridge': bridge
  }

  // call setXDomainMessenger(...)
  console.log('Calling `setXDomainMessenger(...)` and waiting for 3 confirmations..');
  let xdomain_tx = await contract.setXDomainMessenger(
    '0x4200000000000000000000000000000000000007',
    consts.callOptions
  ); xdomain_tx.wait(3);
  w_data.setXDomainMessenger = extractData(xdomain_tx);
  w_data.setXDomainMessenger.inputs = {
    '_messenger': '0x4200000000000000000000000000000000000007'
  }

  console.log('Initialized destination contract\n')

  return w_data;
}

async function initializeBridge(contract, version, src, dest, data) {
  
  // TODO : Set nonce manually

  let w_data = {}

  // call initialize(...)
  console.log('Calling `initialize(...) on bridge contract. Waiting for 3 confirmations..');
  let init_tx = await contract.initialize(
    version,
    '0x4361d0f75a0186c05f971c566dc6bea5957483fd',
    '0x22f24361d548e5faafb36d1437839f080363982b',
    consts.callOptions
  ); init_tx = init_tx.wait(3);
  w_data.initialize = extractData(init_tx);
  w_data.initialize.inputs = {
    '_version': version,
    '_messenger': '0x4361d0f75a0186c05f971c566dc6bea5957483fd',
    '_stdBridge': '0x22f24361d548e5faafb36d1437839f080363982b'
  }

  // call setSource(...)
  console.log('Setting source contract and waiting for 3 confirmations..');
  let src_tx = await contract.setSource(
    src,
    consts.callOptions
  ); src_tx = src_tx.wait(3);
  w_data.setSource = extractData(src_tx);
  w_data.setSource.inputs = {
    '_src': src
  }

  // call setDestination(...)
  console.log('Setting destination contract and waiting for 3 confirmations..');
  let dest_tx = await contract.setDestination(
    dest,
    consts.callOptions
  ); dest_tx = dest_tx.wait(3);
  w_data.setDestination = extractData(dest_tx);
  w_data.setDestination.inputs = {
    '_dest': dest
  }

  // call addTokenMap(...)
  console.log('Adding base token mapping and waiting for 3 confirmations..');
  let map_tx = await contract.addTokenMap(
    '0x0000000000000000000000000000000000000000',
    '0x0000000000000000000000000000000000000000',
    consts.callOptions
  ); map_tx = map_tx.wait(3);
  w_data.addTokenMap = extractData(map_tx);
  w_data.addTokenMap.inputs = {
    '_l2TokenAddress': '0x0000000000000000000000000000000000000000',
    '_l1TokenAddress': '0x0000000000000000000000000000000000000000'
  }

  // call addBuddleBridge(...)
  // TODO

  console.log('Initialized bridge contract\n')

  return w_data;
}

async function main(version, contracts, deployed) {
  // contracts take bytes32 and not string
  version = ethers.utils.formatBytes32String(version);
  let w_data = {}
  let network = 'Optimism'

  // find compatible networks and extract contract addresses
  // includes self
  let commonl1 = [];
  for (key of Object.keys(deployed)) {
    if (deployed[key]['l1network'] == deployed[network]['l1network']) {
      let item = {
        chain: consts.chainID[deployed[key]['l2network']],
        source: deployed[key]['source']['address'],
        destination: deployed[key]['destination']['address'],
        bridge: deployed[key]['bridge']['address']
      }
      commonl1.push(item);
    }
  }

  // Initialize the contracts
  w_data.source = {}
  w_data.source.address = contracts.source.address;
  w_data.source.functions = await initiailizeSrc(
    contracts.source, 
    version, 
    contracts.bridge.address, 
    commonl1
  );
  w_data.destination = {}
  w_data.destination.address = contracts.destination.address;
  w_data.destination.functions = await initiailizeDest(
    contracts.destination, 
    version,
    contracts.bridge.address
  );
  w_data.bridge = {}
  w_data.bridge.address = contracts.bridge.address,
  w_data.bridge.functions = await initializeBridge(
    contracts.bridge, 
    version, 
    contracts.source.address, 
    contracts.destination.address, 
    commonl1
  )

  // Write to file for record keeping
  const file = fs.readFileSync(`${__dirname}/initialized.json`);
  const data = JSON.parse(file);
  data[network] = w_data;
  fs.writeFileSync(`${__dirname}/initialized.json`, JSON.stringify(data, null, 4));
  console.log(`Written call details to ${__dirname}/initialized.json`);
  console.log('Exiting..')
}

module.exports = main;