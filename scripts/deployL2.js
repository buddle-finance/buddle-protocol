const hre = require("hardhat");
const fs = require("fs");

const explorers = {
  opKovan: "https://kovan-optimistic.etherscan.io/address/",
  arbRinkeby: "https://testnet.arbiscan.io/address/",
  arbNitro: "https://nitro-devnet-explorer.arbitrum.io/address/",
  bobaRinkeby: "https://blockexplorer.rinkeby.boba.network/address/"
}

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
  const srcDeployment = await srcContract.deployTransaction.wait();

  // deploy destination contract
  const DestinationContract = await hre.ethers.getContractFactory(dst);
  const dstContract = await DestinationContract.deploy();
  const dstDeployment = await dstContract.deployTransaction.wait();

  
  console.log(`Storing deployment information..`)
  const extractData = (result) => {
    return {
      from: result.from,
      block: {
        hash: result.blockHash,
        number: result.blockNumber
      },
      gas: result.cumulativeGasUsed,
      txHash: result.transactionHash,
      address: result.contractAddress,
      url: explorers[process.env.HARDHAT_NETWORK] + result.contractAddress
    }
  }
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
    console.log("Please manually verify contract on sourcify.dev")
    // TODO :: HH303 Unrecognized task `sourcify`
    // await hre.run("sourcify", {
    //   contractName: src
    // });
    // await hre.run("sourcify", {
    //   contractName: dst
    // });
  } else {
    await hre.run("verify:verify", {
      address: srcContract.address,
      contract: src
    });
    await hre.run("verify:verify", {
      address: dstContract.address,
      contract: dst
    });
  }


  // output addresses delimited by a space
  console.log(srcContract.address + " " + dstContract.address);
  
}

let l2 = process.argv[2];
l2 = l2[0].toUpperCase() + l2.substring(1);

main(l2)
  .then( () => { process.exitCode = 0; } )
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
