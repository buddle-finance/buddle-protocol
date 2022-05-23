## Deployed Contracts

### Optimism Kovan
> Chain ID: 69

- Source : [`0xaA3F37985eb895a4326159F0643D4198BA6A2960`](https://kovan-optimistic.etherscan.io/address/0xaA3F37985eb895a4326159F0643D4198BA6A2960#code)
- Bridge : [`0xc3b874877c2e97Bb9E9F737E5845F243B7a58c9C`](https://kovan.etherscan.io/address/0xc3b874877c2e97Bb9E9F737E5845F243B7a58c9C#code)
- Destination : [`0xC3736cf917b825b979986b53A23Cb8b4821ddc67`](https://kovan-optimistic.etherscan.io/address/0xC3736cf917b825b979986b53A23Cb8b4821ddc67#code)

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
| | _buddleBridge | 0xc3b874877c2e97Bb9E9F737E5845F243B7a58c9C |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
| | _stdBridge | 0x4200000000000000000000000000000000000010 |
| addDestination | _chain | 69 |
| | _contract | 0xC3736cf917b825b979986b53A23Cb8b4821ddc67 |


[BuddleBridgeOptimism.sol](BuddleBridgeOptimism.sol)

| func | var | Kovan |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _messenger | 0x4361d0f75a0186c05f971c566dc6bea5957483fd |
| | _stdBridge | 0x22f24361d548e5faafb36d1437839f080363982b |
| setSource | _src | 0xaA3F37985eb895a4326159F0643D4198BA6A2960 |
| setDestination | _dest | 0xC3736cf917b825b979986b53A23Cb8b4821ddc67 |
| addTokenMap | _l2TokenAddress | 0x0000000000000000000000000000000000000000 |
| | _l1TokenAddress | 0x0000000000000000000000000000000000000000 |


[BuddleDestOptimism.sol](BuddleDestOptimism.sol)

| func | var | Kovan |
| --- | --- | --- |
| initialize | _version | v0.1.0 |
| | _buddleBridge | 0xc3b874877c2e97Bb9E9F737E5845F243B7a58c9C |
| setXDomainMessenger | _messenger | 0x4200000000000000000000000000000000000007 |
