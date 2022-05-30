const hre = require("hardhat");
const fs = require("fs");
const extractData = require("./utils.js");

async function main(iden) {
  // Compile the files
  await hre.run('compile');

  // Build path
  const dir = `contracts/${iden.toLowerCase()}`;
  const src = `${dir}/BuddleSrc${iden}.sol:BuddleSrc${iden}`;
  const dst = `${dir}/BuddleDest${iden}.sol:BuddleDest${iden}`;


  console.log(`deploying source and desination contracts on ${process.env.HARDHAT_NETWORK}..`)
  
  // deploy source contract
  const SourceContract = await hre.ethers.getContractFactory(src);
  const srcContract = await SourceContract.deploy();
  console.log("deployed source contract.. waiting for 5 confirmations..");
  const srcDeployment = await srcContract.deployTransaction.wait(5);

  // deploy destination contract
  const DestinationContract = await hre.ethers.getContractFactory(dst);
  const dstContract = await DestinationContract.deploy();
  console.log("deployed destination contract.. waiting for 5 confirmations..");
  const dstDeployment = await dstContract.deployTransaction.wait(5);

  
  console.log(`Storing deployment information..`)
  const srcData = extractData(srcDeployment);
  const dstData = extractData(dstDeployment);

  const file = fs.readFileSync(`${__dirname}/deployed.json`, "utf-8");
  const data = JSON.parse(file);
  if (data[iden] == undefined) data[iden] = {};
  data[iden].l2network = process.env.HARDHAT_NETWORK;
  data[iden].source = srcData;
  data[iden].destination = dstData;
  fs.writeFileSync(`${__dirname}/deployed.json`, JSON.stringify(data, null, 4));
  console.log(`Written contract details to ${__dirname}/deployed.json`);


  // verify contracts
  console.log("Verifying source and destination contracts..");
  if (["boba", "nitro"].includes(iden.toLowerCase())) {
    // TODO :: HH303 Unrecognized task `sourcify`
    console.log("Please manually verify source and destination contracts on sourcify.dev")
    // await hre.run("sourcify", {
    //   contractName: src
    // });
    // await hre.run("sourcify", {
    //   contractName: dst
    // });
  } else {
    try {
      await hre.run("verify:verify", {
        address: srcData.address,
        contract: src
      });
    } catch(err) {
      console.log("error in verifying source..");
      console.log(err);
    }
    try {
      await hre.run("verify:verify", {
        address: dstData.address,
        contract: dst
      });
    } catch(err) {
      console.log("error in verifying destination..");
      console.log(err);
    }
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
