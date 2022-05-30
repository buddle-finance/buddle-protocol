const explorers = {
  opKovan: "https://kovan-optimistic.etherscan.io/address/",
  arbRinkeby: "https://testnet.arbiscan.io/address/",
  arbNitro: "https://nitro-devnet-explorer.arbitrum.io/address/",
  bobaRinkeby: "https://blockexplorer.rinkeby.boba.network/address/",
  kovan: "https://kovan.etherscan.io/address/",
  rinkeby: "https://rinkeby.etherscan.io/address/",
  goerli: "https://goerli.etherscan.io/address/"
}

module.exports = (result) => {
  return {
    from: result.from,
    block: {
      hash: result.blockHash,
      number: result.blockNumber
    },
    gas: parseInt(result.cumulativeGasUsed, 16),
    txHash: result.transactionHash,
    address: result.contractAddress,
    url: explorers[process.env.HARDHAT_NETWORK] + result.contractAddress
  }
}