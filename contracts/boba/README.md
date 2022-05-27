## Deployed Contracts

### Boba Rinkeby
> Chain ID: 28

- Source : [`0x3ec618E37e00E19bc2b139D0C3aa02feFe692E28`](https://blockexplorer.rinkeby.boba.network/address/0x3ec618E37e00E19bc2b139D0C3aa02feFe692E28/contracts)
- Bridge : [`0x2A5B776b61c330854D6CdE8d8D0f247bed44BB76`](https://rinkeby.etherscan.io/address/0x2A5B776b61c330854D6CdE8d8D0f247bed44BB76#code)
- Destination : [`0x9869Fc26826172eB8fB334b39B8D865Be36b01C3`](https://blockexplorer.rinkeby.boba.network/address/0x9869Fc26826172eB8fB334b39B8D865Be36b01C3/contracts)

### Boba Mainnet
> Chain ID: 288

COMING SOON

## Initiation Values

[BuddleSrcBoba.sol](BuddleSrcBoba.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _feeBasisPoints | 5 |
| | _feeRampUp | 60 |
| | _buddleBridge | 0x2A5B776b61c330854D6CdE8d8D0f247bed44BB76 |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
| | _stdBridge | 0x4200000000000000000000000000000000000010 |
| addDestination | _chain | 28 |
| | _contract | 0x9869Fc26826172eB8fB334b39B8D865Be36b01C3 |
| addDestination | _chain | 421611 |
| | _contract | 0xcb122d5dFD3e2b16b07dd95F78AB745CaC086c00 |


[BuddleBridgeBoba.sol](BuddleBridgeBoba.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _messenger | 0xF10EEfC14eB5b7885Ea9F7A631a21c7a82cf5D76 |
| | _stdBridge | 0xDe085C82536A06b40D20654c2AbA342F2abD7077 |
| setSource | _src | 0x3ec618E37e00E19bc2b139D0C3aa02feFe692E28 |
| setDestination | _dest | 0x9869Fc26826172eB8fB334b39B8D865Be36b01C3 |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |
| addBuddleBridge | _chain | 421611 |
| | _contract | 0x23EbB8DC02c58C6Ad4B0b89BbDCB0441F63Dd835 |


[BuddleDestBoba.sol](BuddleDestBoba.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _buddleBridge | 0x2A5B776b61c330854D6CdE8d8D0f247bed44BB76 |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
