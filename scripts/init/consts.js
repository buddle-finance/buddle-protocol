const CONTRACT_FEE_BASIS_POINTS = 5;
const CONTRACT_FEE_RAMPUP = 15;

const chainID = {
  opKovan: 69,
  arbRinkeby: 421611,
  arbNitro: 421612,
  bobaRinkeby: 28
}

const callOptions = {
  gasPrice: 100000,
  gasLimit: 1000000
}

module.exports = {
  CONTRACT_FEE_BASIS_POINTS,
  CONTRACT_FEE_RAMPUP,
  chainID,
  callOptions
}