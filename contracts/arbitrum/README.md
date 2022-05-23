## Deployed Contracts

### Arbitrum Rinkeby
> Chain ID: 421611

- Source : [``]()
- Bridge : [``]()
- Destination : [``]()

### Arbitrum Nitro (Goerli)
> Chain ID: 421612

- Source : [``]()
- Bridge : [``]()
- Destination : [``]()

### Arbitrum Mainnet
> Chain ID: 42161

COMING SOON

## Initiation Values

[BuddleSrcArbitrum.sol](BuddleSrcArbitrum.sol), [BuddleSrcNitro.sol](BuddleSrcNitro.sol)

| func | var | Rinkeby | Nitro |
| --- | --- | --- | --- |
| initialize | _version | v0.1.0 | v0.1.0 |
| | _feeBasisPoints | 5 | 5 |
| | _feeRampUp | 60 | 60 |
| | _buddleBridge | | |
| setXDomainMessenger | _arbSys | 0x0000000000000000000000000000000000000064 | 0x0000000000000000000000000000000000000064 |
| | _gatewayRouter | 0x9413AD42910c1eA60c737dB5f58d1C504498a3cD | 0xC502Ded1EE1d616B43F7f20Ebde83Be1A275ca3c |
| addDestination | _chain | 421611 | 421612 |
| | _contract | | |
| addDestination | _chain | 28 | |
| | _contract | | |


[BuddleBridgeArbitrum.sol](BuddleBridgeArbitrum.sol), [BuddleBridgeNitro.sol](BuddleBridgeNitro.sol)

| func | var | Rinkeby | Nitro |
| --- | --- | --- | --- |
| initialize | _version | v0.1.0 | v0.1.0 |
| | _gatewayRouter | 0x70C143928eCfFaf9F5b406f7f4fC28Dc43d68380 | 0x8BDFa67ace22cE2BFb2fFebe72f0c91CDA694d4b |
| | _arbInbox | 0x578BAde599406A8fE3d24Fd7f7211c0911F5B29e | 0x1FdBBcC914e84aF593884bf8e8Dd6877c29035A2 |
| | _arbOutbox | 0x2360A33905dc1c72b12d975d975F42BaBdcef9F3 | 0xFDF2B11347dA17326BAF30bbcd3F4b09c4719584 |
| setSource | _src | | |
| setDestination | _dest | | |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 | 0x0000000000000000000000000000000000000000 |


[BuddleDestArbitrum.sol](BuddleDestArbitrum.sol), [BuddleDestNitro.sol](BuddleDestNitro.sol)

| func | var | Rinkeby | Nitro |
| --- | --- | --- | --- |
| initialize | _version | v0.1.0 | v0.1.0 |
| | _buddleBridge | | |
