## Deployed Contracts

### Arbitrum Rinkeby
> Chain ID: 421611

- Source : [`0x8B38d13D5548ECa036686b73d7e85bd31b6B6d55`](https://testnet.arbiscan.io/address/0x8B38d13D5548ECa036686b73d7e85bd31b6B6d55#code)
- Bridge : [`0x0A16976ccdF08869DdF1511ae14C3B1467073d23`](https://rinkeby.etherscan.io/address/0x0A16976ccdF08869DdF1511ae14C3B1467073d23#code)
- Destination : [`0x359CD2a739B3df966b325aEA868F4a8a63edAEb1`](https://testnet.arbiscan.io/address/0x359CD2a739B3df966b325aEA868F4a8a63edAEb1#code)

### Arbitrum Mainnet
> Chain ID: 42161

COMING SOON

## Initiation Values

[BuddleSrcArbitrum.sol](BuddleSrcArbitrum.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _feeBasisPoints | 5 |
| | _feeRampUp | 60 |
| | _buddleBridge | 0x0A16976ccdF08869DdF1511ae14C3B1467073d23 |
| setXDomainMessenger | _arbSys | 0x0000000000000000000000000000000000000064 |
| | _gatewayRouter | 0x9413AD42910c1eA60c737dB5f58d1C504498a3cD |
| addDestination | _chain | 421611 |
| | _contract | 0x359CD2a739B3df966b325aEA868F4a8a63edAEb1 |
| addDestination | _chain | 28 |
| | _contract | 0x359CD2a739B3df966b325aEA868F4a8a63edAEb1 |


[BuddleBridgeArbitrum.sol](BuddleBridgeArbitrum.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _gatewayRouter | 0x70C143928eCfFaf9F5b406f7f4fC28Dc43d68380 |
| | _arbInbox | 0x578BAde599406A8fE3d24Fd7f7211c0911F5B29e |
| | _arbOutbox | 0x2360A33905dc1c72b12d975d975F42BaBdcef9F3 |
| setSource | _src | 0x8B38d13D5548ECa036686b73d7e85bd31b6B6d55 |
| setDestination | _dest | 0x359CD2a739B3df966b325aEA868F4a8a63edAEb1 |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |
| addBuddleBridge | _chain | 28 |
| | _contract | 0x962256d87Dcaa80404503dd0816a58f122224375 |


[BuddleDestArbitrum.sol](BuddleDestArbitrum.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _buddleBridge | 0x0A16976ccdF08869DdF1511ae14C3B1467073d23 |
