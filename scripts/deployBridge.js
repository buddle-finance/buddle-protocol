const hre = require("hardhat");
const fs = require("fs");
const extractData = require("./utils.js");

async function main(iden) {
  // Compile the files
  await hre.run('compile');

  // build path
  const dir = `contracts/${iden.toLowerCase()}`;
  const bdg = `${dir}/BuddleBridge${iden}.sol:BuddleBridge${iden}`


  console.log(`deploying bridge contract on ${process.env.HARDHAT_NETWORK}`);

  // deploy bridge contract
  const BridgeContract = await hre.ethers.getContractFactory(bdg);
  const bdgContract = await BridgeContract.deploy();
  console.log("deployed bridge contract.. waiting for 5 confirmations..");
  const bdgDeployment = await bdgContract.deployTransaction.wait(5);


  console.log("storing deployment information..");
  const bdgData = extractData(bdgDeployment);

  const file = fs.readFileSync(`${__dirname}/deployed.json`, "utf-8");
  const data = JSON.parse(file);
  if (data[iden] == undefined) data[iden] = {};
  data[iden].l1network = process.env.HARDHAT_NETWORK;
  data[iden].bridge = bdgData;
  fs.writeFileSync(`${__dirname}/deployed.json`, JSON.stringify(data, null, 4));
  console.log(`Written contract details to ${__dirname}/deployed.json`);


  // verifying contract
  console.log("verifying bridge contract..")
  try {
    await hre.run("verify:verify", {
      address: bdgData.address,
      contract: bdg
    });
  } catch(err) {
    console.log("error in verifying bridge..");
    console.log(err);
  }
}

let l2 = process.argv[2];
l2 = l2[0].toUpperCase() + l2.substring(1);

main(l2)
  .then( () => { process.exitCode = 0; } )
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
