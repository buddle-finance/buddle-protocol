const hre = require("hardhat");

async function main(iden) {
  // Compile the files
  await hre.run('compile');

  // deploy bridge contract
  const BridgeContract = await hre.ethers
    .getContractFactory(`contracts/${iden.toLowerCase()}/BuddleBridge${iden}.sol:BuddleBridge${iden}`);
  const bdgContract = await BridgeContract.deploy();
  await bdgContract.deployed();

  // output addresses delimited by a space
  console.log(bdgContract.address);
  
}

let l2 = process.argv[2];
l2 = l2[0].toUpperCase() + l2.substring(1);

main(l2)
  .then( () => { process.exitCode = 0; } )
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
