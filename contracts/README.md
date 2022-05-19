## Deployed Contracts

The following contracts are currently deployed on testnets. The values in blockquotes are contract initiation values.

### Optimism Contracts
> On Kovan and Optimistic-Kovan

- Source : [`0xc77852B84CD99Fab93a5199928172c988335568C`](https://kovan-optimistic.etherscan.io/address/0xc77852B84CD99Fab93a5199928172c988335568C#code)
> `initialize(...)` : _feeBasisPoints = `5`, _feeRampUp = `120`, _buddleBridge = `0x230e86922D90F2416239C891938DdD0078769DaF`
> `setXDomainMessenger(...)` : _messenger = `0x4200000000000000000000000000000000000007`, _stdBridge = `0x4200000000000000000000000000000000000010`
> `addDestination(...)` : _chain = `69`, _contract = `0x53fF9D8D8416497fbe1B352F509f072b276489A9`

- Bridge : [`0x230e86922D90F2416239C891938DdD0078769DaF`](https://kovan.etherscan.io/address/0x230e86922D90F2416239C891938DdD0078769DaF#code)
> `initialize(...)` : _messenger = `0x4361d0f75a0186c05f971c566dc6bea5957483fd`, _stdBridge = `0x22f24361d548e5faafb36d1437839f080363982b`
> `setSource(...)` : _src = `0xc77852B84CD99Fab93a5199928172c988335568C`
> `setDestination(...)` : _dest = `0x53fF9D8D8416497fbe1B352F509f072b276489A9`
> `addTokenMap(...)` : _l2TokenAddress = `0x0000000000000000000000000000000000000000`, _l1TokenAddress = `0x0000000000000000000000000000000000000000`

- Destination : [`0x53fF9D8D8416497fbe1B352F509f072b276489A9`](https://kovan-optimistic.etherscan.io/address/0x53fF9D8D8416497fbe1B352F509f072b276489A9#code)
> `initialize(...)` : _buddleBridge = `0x230e86922D90F2416239C891938DdD0078769DaF`
> `setXDomainMessenger(...)` : _messenger = `0x4200000000000000000000000000000000000007`

### Arbitrum Contracts

### Polygon Contracts

### zkSync Contracts

### Boba Network Contracts

## User Flow
> To be updated

**For the user**

1. Calls `deposit()` on the Source Contract to start the transfer for a particular chain
2. A LP calls `deposit()` on the Destination Contract to complete the transfer

**For the bounty seeker**

1. Creates a ticket for a particular destination chain
2. Provide liquidity on mainnet bridge contract
3. Transfer amounts + bounty fees are received by bounty seeker

**For liquidity provider**

1. Call `deposit()` on the Destination Contract to complete a transfer (minus LPfee)
2. Wait for ticket to be confirmed
3. Wait for funds to bridge
4. Call `withdraw()` on the Destination Contract to receive full amount
