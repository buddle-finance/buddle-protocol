## Deployed Contracts

### Arbitrum Rinkeby
> Chain ID: 421611

- Source : [`0x9869Fc26826172eB8fB334b39B8D865Be36b01C3`](https://testnet.arbiscan.io/address/0x9869Fc26826172eB8fB334b39B8D865Be36b01C3#code)
- Bridge : [`0x23EbB8DC02c58C6Ad4B0b89BbDCB0441F63Dd835`](https://rinkeby.etherscan.io/address/0x1e986476FB4C0D1a3600954d9C422160ff850774#code)
- Destination : [`0xcb122d5dFD3e2b16b07dd95F78AB745CaC086c00`](https://testnet.arbiscan.io/address/0xcb122d5dFD3e2b16b07dd95F78AB745CaC086c00#code)

### Arbitrum Mainnet
> Chain ID: 42161

COMING SOON

## Initiation Values

[BuddleSrcArbitrum.sol](BuddleSrcArbitrum.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _feeBasisPoints | 5 |
| | _feeRampUp | 60 |
| | _buddleBridge | 0x23EbB8DC02c58C6Ad4B0b89BbDCB0441F63Dd835 |
| setXDomainMessenger | _arbSys | 0x0000000000000000000000000000000000000064 |
| | _gatewayRouter | 0x9413AD42910c1eA60c737dB5f58d1C504498a3cD |
| addDestination | _chain | 421611 |
| | _contract | 0xcb122d5dFD3e2b16b07dd95F78AB745CaC086c00 |
| addDestination | _chain | 28 |
| | _contract | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |


[BuddleBridgeArbitrum.sol](BuddleBridgeArbitrum.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _gatewayRouter | 0x70C143928eCfFaf9F5b406f7f4fC28Dc43d68380 |
| | _arbInbox | 0x578BAde599406A8fE3d24Fd7f7211c0911F5B29e |
| | _arbOutbox | 0x2360A33905dc1c72b12d975d975F42BaBdcef9F3 |
| setSource | _src | 0x9869Fc26826172eB8fB334b39B8D865Be36b01C3 |
| setDestination | _dest | 0xcb122d5dFD3e2b16b07dd95F78AB745CaC086c00 |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |
| addBuddleBridge | _chain | 28 |
| | _contract | 0x97fBc3503349744bEd031F96BCfc6449d7b6e3fB |


[BuddleDestArbitrum.sol](BuddleDestArbitrum.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _buddleBridge | 0x23EbB8DC02c58C6Ad4B0b89BbDCB0441F63Dd835 |
