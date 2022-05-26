## Deployed Contracts

### Boba Rinkeby
> Chain ID: 28

- Source : [`0x8B38d13D5548ECa036686b73d7e85bd31b6B6d55`](https://blockexplorer.rinkeby.boba.network/address/0x8B38d13D5548ECa036686b73d7e85bd31b6B6d55/contracts)
- Bridge : [`0x962256d87Dcaa80404503dd0816a58f122224375`](https://rinkeby.etherscan.io/address/0x962256d87dcaa80404503dd0816a58f122224375#code)
- Destination : [`0x359CD2a739B3df966b325aEA868F4a8a63edAEb1`](https://blockexplorer.rinkeby.boba.network/address/0x359CD2a739B3df966b325aEA868F4a8a63edAEb1/contracts)

### Boba Mainnet
> Chain ID: 288

COMING SOON

## Initiation Values

[BuddleSrcBoba.sol](BuddleSrcBoba.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _feeBasisPoints | 5 |
| | _feeRampUp | 60 |
| | _buddleBridge | 0x962256d87Dcaa80404503dd0816a58f122224375 |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
| | _stdBridge | 0x4200000000000000000000000000000000000010 |
| addDestination | _chain | 28 |
| | _contract |  |
| addDestination | _chain | 421611 |
| | _contract | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |


[BuddleBridgeBoba.sol](BuddleBridgeBoba.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _messenger | 0xF10EEfC14eB5b7885Ea9F7A631a21c7a82cf5D76 |
| | _stdBridge | 0xDe085C82536A06b40D20654c2AbA342F2abD7077 |
| setSource | _src | 0x8B38d13D5548ECa036686b73d7e85bd31b6B6d55 |
| setDestination | _dest | 0x359CD2a739B3df966b325aEA868F4a8a63edAEb1 |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |
| addBuddleBridge | _chain | 421611 |
| | _contract | 0x1e986476FB4C0D1a3600954d9C422160ff850774 |


[BuddleDestBoba.sol](BuddleDestBoba.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _buddleBridge | 0x962256d87Dcaa80404503dd0816a58f122224375 |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
