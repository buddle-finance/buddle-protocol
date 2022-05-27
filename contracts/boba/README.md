## Deployed Contracts

### Boba Rinkeby
> Chain ID: 28

- Source : [`0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c`](https://blockexplorer.rinkeby.boba.network/address/0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c/contracts)
- Bridge : [`0x97fBc3503349744bEd031F96BCfc6449d7b6e3fB`](https://rinkeby.etherscan.io/address/0x97fBc3503349744bEd031F96BCfc6449d7b6e3fB#code)
- Destination : [`0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e`](https://blockexplorer.rinkeby.boba.network/address/0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e/contracts)

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
| | _buddleBridge | 0x97fBc3503349744bEd031F96BCfc6449d7b6e3fB |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
| | _stdBridge | 0x4200000000000000000000000000000000000010 |
| addDestination | _chain | 28 |
| | _contract | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |
| addDestination | _chain | 421611 |
| | _contract | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |


[BuddleBridgeBoba.sol](BuddleBridgeBoba.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _messenger | 0xF10EEfC14eB5b7885Ea9F7A631a21c7a82cf5D76 |
| | _stdBridge | 0xDe085C82536A06b40D20654c2AbA342F2abD7077 |
| setSource | _src | 0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c |
| setDestination | _dest | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |
| addBuddleBridge | _chain | 421611 |
| | _contract | 0x23EbB8DC02c58C6Ad4B0b89BbDCB0441F63Dd835 |


[BuddleDestBoba.sol](BuddleDestBoba.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _buddleBridge | 0x97fBc3503349744bEd031F96BCfc6449d7b6e3fB |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
