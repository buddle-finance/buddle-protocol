#!/usr/bin/bash

echo "Bash Version: ${BASH_VERSION}"
dir=$(dirname $0)

# Get layer2 info and convert to lowercase
read -p "which L2? [Optimism, Arbitrum, Nitro, Boba, Polygon, ZkSync] " chain
chain=$(echo "$chain" | tr [:upper:] [:lower:])

# case match for network
case "$chain" in
  "optimism")
    NETWORK_L1="kovan"
    NETWORK_L2="opKovan"
  ;;
  "arbitrum")
    NETWORK_L1="rinkeby"
    NETWORK_L2="arbRinkeby"
  ;;
  "nitro")
    NETWORK_L1="goerli"
    NETWORK_L2="arbNitro"
  ;;
  "boba")
    NETWORK_L1="rinkeby"
    NETWORK_L2="bobaRinkeby"
  ;;
  "polygon")
    echo cannot deploy yet
    exit 1
  ;;
  "zksync")
    echo fix issues before deploying
    exit 1
  ;;
  *)
    echo invalid input
    exit 1
esac

# inform of layer2 and networks
echo "Deploying contracts for: $chain"
echo "L1 network: $NETWORK_L1"
echo "L2 network: $NETWORK_L2"

### Hardhat stuff ###

# Deploy and verify L2 contracts
export HARDHAT_NETWORK=$NETWORK_L2
node $dir/deployL2.js $chain # handles verification as well

# Deploy and verify L1 bridge contract
export HARDHAT_NETWORK=$NETWORK_L1
node $dir/deployBridge.js $chain # handles verification as well

### echo and exit ###

# echo contract addresses
echo "please see scripts/deployed.json for deployment information"

if [ $chain == "boba" ] && [ $chain == "nitro" ] # Boba and Nitro are not etherscan
  then
  echo "please verify the L2 contracts on https://sourcify.dev before running initialize.js"
  else
  echo "please run initialize.js to initialize the contracts"
fi 

# Clear env vars
unset HARDHAT_NETWORK