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
out=$(node $dir/deployL2.js $chain) # Nothing to compile\n<srcAddr> <dstAddr>

src=$(echo "$out" | tail -1 | cut -d " " -f 1)
dst=$(echo "$out" | tail -1 | cut -d " " -f 2)

# Deploy and verify L1 bridge contract
export HARDHAT_NETWORK=$NETWORK_L1
out=$(node $dir/deployBridge.js $chain) # Nothing to compile\n<bdgAddr>
bdg=$(echo "$out" | tail -1)

### echo and exit ###

# echo contract addresses
echo "Source Contract Address: $src"
echo "Destination Contract Address: $dst"
echo "Bridge Contract Address: $bdg"

if [ $chain != "boba" ] # Boba is not etherscan
  then
  echo "please run the following to verify contracts: \n\
npx hardhat verify --network $NETWORK_L2 $src && \
npx hardhat verify --network $NETWORK_L2 $dst && \
npx hardhat verify --network $NETWORK_L1 $bdg"
  else
  echo -e "please run the following to verify contracts: \n \
npx hardhat verify --network $NETWORK_L1 $bdg"
fi 

# Clear env vars
unset HARDHAT_NETWORK