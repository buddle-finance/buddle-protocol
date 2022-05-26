## Deployed Contracts

### Optimism Kovan
> Chain ID: 69

- Source : [`0x923266F0F6D3a66Ad23a6cD8CEb3512f24258B85`](https://kovan-optimistic.etherscan.io/address/0x923266F0F6D3a66Ad23a6cD8CEb3512f24258B85#code)
- Bridge : [`0xe396721BF9FD7c320c3c528077428847c4940C65`](https://kovan.etherscan.io/address/0xe396721BF9FD7c320c3c528077428847c4940C65#code)
- Destination : [`0x556591FABb4cCc4a417093d2a991713E1ba58372`](https://kovan-optimistic.etherscan.io/address/0x556591FABb4cCc4a417093d2a991713E1ba58372#code)

### Optimism Mainnet
> Chain ID: 10

COMING SOON

## Initiation Values

[BuddleSrcOptimism.sol](BuddleSrcOptimism.sol)

| func | var | Kovan |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _feeBasisPoints | 5 |
| | _feeRampUp | 60 |
| | _buddleBridge | 0xe396721BF9FD7c320c3c528077428847c4940C65 |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
| | _stdBridge | 0x4200000000000000000000000000000000000010 |
| addDestination | _chain | 69 |
| | _contract | 0x556591FABb4cCc4a417093d2a991713E1ba58372 |


[BuddleBridgeOptimism.sol](BuddleBridgeOptimism.sol)

| func | var | Kovan |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _messenger | 0x4361d0f75a0186c05f971c566dc6bea5957483fd |
| | _stdBridge | 0x22f24361d548e5faafb36d1437839f080363982b |
| setSource | _src | 0x923266F0F6D3a66Ad23a6cD8CEb3512f24258B85 |
| setDestination | _dest | 0x556591FABb4cCc4a417093d2a991713E1ba58372 |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |


[BuddleDestOptimism.sol](BuddleDestOptimism.sol)

| func | var | Kovan |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _buddleBridge | 0xe396721BF9FD7c320c3c528077428847c4940C65 |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
