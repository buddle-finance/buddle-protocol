## Deployed Contracts

### Boba Rinkeby

- Source : [``]()
- Bridge : [``]()
- Destination : [``]()

### Boba Mainnet

COMING SOON

## Initiation Values

**[`BuddleSrcBoba.sol`](BuddleSrcBoba.sol)**

| func | var | Rinkeby |
| --- | --- | --- |
| `initialize` | _version | `v0.1.0` |
| | _feeBasisPoints | `5` |
| | _feeRampUp | `60` |
| | _buddleBridge | `` |
| `setXDomainMessenger` | _messenger | `0x4200000000000000000000000000000000000007` |
| | _stdBridge | `0x4200000000000000000000000000000000000010` |
| `addDestination` | _chain | `28` |
| | _contract | `` |
| `addDestination` | _chain | `421611` |
| | _contract | `` |


**[`BuddleBridgeBoba.sol`](BuddleBridgeBoba.sol)**

| func | var | Rinkeby |
| --- | --- | --- |
| `initialize` | _version | `v0.1.0` |
| | _messenger | `0xF10EEfC14eB5b7885Ea9F7A631a21c7a82cf5D76` |
| | _stdBridge | `0xDe085C82536A06b40D20654c2AbA342F2abD7077` |
| `setSource` | _src | `` |
| `setDestination` | _dest | `` |
| `addTokenMap` | _l2TokenAddress | `0x0000000000000000000000000000000000000000` |
| | _l1TokenAddress | `0x0000000000000000000000000000000000000000` |


**[`BuddleDestBoba.sol`](BuddleDestBoba.sol)**

| func | var | Rinkeby |
| --- | --- | --- |
| `initialize` | _version | `v0.1.0` |
| | _buddleBridge | `` |
| `setXDomainMessenger` | _messenger | `0x4200000000000000000000000000000000000007` |
