const hre = require("hardhat");

async function main(iden) {
  // Compile the files
  await hre.run('compile');

  // deploy source contract
  const SourceContract = await hre.ethers
    .getContractFactory(`contracts/${iden.toLowerCase()}/BuddleSrc${iden}.sol:BuddleSrc${iden}`);
  const srcContract = await SourceContract.deploy();
  await srcContract.deployed();

  // deploy destination contract
  const DestinationContract = await hre.ethers
    .getContractFactory(`contracts/${iden.toLowerCase()}/BuddleDest${iden}.sol:BuddleDest${iden}`);
  const dstContract = await DestinationContract.deploy();
  await dstContract.deployed();

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
