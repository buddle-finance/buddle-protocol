## Deployed Contracts

### Optimism Kovan

- Source : [``]()
- Bridge : [``]()
- Destination : [``]()

### Optimism Mainnet

COMING SOON

## Initiation Values

[BuddleSrcOptimism.sol](BuddleSrcOptimism.sol)

| func | var | Kovan |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _feeBasisPoints | 5 |
| | _feeRampUp | 60 |
| | _buddleBridge |  |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
| | _stdBridge | 0x4200000000000000000000000000000000000010 |
| addDestination | _chain | 69 |
| | _contract |  |


[BuddleBridgeOptimism.sol](BuddleBridgeOptimism.sol)

| func | var | Kovan |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _messenger | 0x4361d0f75a0186c05f971c566dc6bea5957483fd |
| | _stdBridge | 0x22f24361d548e5faafb36d1437839f080363982b |
| setSource | _src |  |
| setDestination | _dest |  |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |


[BuddleDestOptimism.sol](BuddleDestOptimism.sol)

| func | var | Kovan |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _buddleBridge |  |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
