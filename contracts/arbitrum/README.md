## Deployed Contracts

### Arbitrum Rinkeby
> Chain ID: 421611

- Source : [`0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c`](https://testnet.arbiscan.io/address/0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c#code)
- Bridge : [`0x1e986476FB4C0D1a3600954d9C422160ff850774`](https://rinkeby.etherscan.io/address/0x1e986476FB4C0D1a3600954d9C422160ff850774#code)
- Destination : [`0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e`](https://testnet.arbiscan.io/address/0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e#code)

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
| | _buddleBridge | 0x1e986476FB4C0D1a3600954d9C422160ff850774 |
| setXDomainMessenger | _arbSys | 0x0000000000000000000000000000000000000064 |
| | _gatewayRouter | 0x9413AD42910c1eA60c737dB5f58d1C504498a3cD |
| addDestination | _chain | 421611 |
| | _contract | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |
| addDestination | _chain | 28 |
| | _contract |  |


[BuddleBridgeArbitrum.sol](BuddleBridgeArbitrum.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _gatewayRouter | 0x70C143928eCfFaf9F5b406f7f4fC28Dc43d68380 |
| | _arbInbox | 0x578BAde599406A8fE3d24Fd7f7211c0911F5B29e |
| | _arbOutbox | 0x2360A33905dc1c72b12d975d975F42BaBdcef9F3 |
| setSource | _src | 0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c |
| setDestination | _dest | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |
| addBuddleBridge | _chain | 28 |
| | _contract |  |


[BuddleDestArbitrum.sol](BuddleDestArbitrum.sol)

| func | var | Rinkeby |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _buddleBridge | 0x1e986476FB4C0D1a3600954d9C422160ff850774 |
