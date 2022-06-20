module.exports = (tx) => {
  return {
    txHash: tx.transactionHash,
    from: tx.from,
    block: {
      hash: tx.blockHash,
      number: tx.blockNumber
    },
    gas: parseInt(tx.cumulativeGasUsed)
  }
}