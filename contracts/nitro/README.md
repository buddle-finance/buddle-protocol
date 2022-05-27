## Deployed Contracts

### Arbitrum Nitro (Goerli)
> Chain ID: 421612

- Source : [`0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c`](https://nitro-devnet-explorer.arbitrum.io/address/0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c/contracts)
- Bridge : [`0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e`](https://goerli.etherscan.io/address/0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e#code)
- Destination : [`0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e`](https://nitro-devnet-explorer.arbitrum.io/address/0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e/contracts)

### Arbitrum Mainnet
> Chain ID: 42161

COMING SOON

## Initiation Values

[BuddleSrcNitro.sol](BuddleSrcNitro.sol)

| func | var | Nitro |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _feeBasisPoints | 5 |
| | _feeRampUp | 60 |
| | _buddleBridge | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |
| setXDomainMessenger | _arbSys | 0x0000000000000000000000000000000000000064 |
| | _gatewayRouter | 0xC502Ded1EE1d616B43F7f20Ebde83Be1A275ca3c |
| addDestination | _chain | 421612 |
| | _contract | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |
| addDestination | _chain | |
| | _contract | |


[BuddleBridgeNitro.sol](BuddleBridgeNitro.sol)

| func | var | Nitro |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _gatewayRouter | 0x8BDFa67ace22cE2BFb2fFebe72f0c91CDA694d4b |
| | _arbInbox | 0x1FdBBcC914e84aF593884bf8e8Dd6877c29035A2 |
| | _arbOutbox | 0xFDF2B11347dA17326BAF30bbcd3F4b09c4719584 |
| setSource | _src | 0xbABe7bF065F0182c1368D032AE22CEE8Cf839D1c |
| setDestination | _dest | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |


[BuddleDestNitro.sol](BuddleDestNitro.sol)

| func | var | Nitro |
| --- | --- | --- |
| initialize | _version | 0x76302e312e3000000000000000000000000000000000000000000000000000 |
| | _buddleBridge | 0x0E239243e8b59e99f98BCbb9D9792ee179C54a7e |
