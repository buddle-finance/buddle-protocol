## Contract Workings

**For the user**

1. Calls `deposit()` on the Source Contract to start the transfer for a particular chain
1a. TransferStarted event is emitted
2. A LP calls `deposit()` on the Destination Contract to complete the transfer

**For the bounty seeker**

1. Creates a ticket for a particular destination chain
1a. TicketCreated event is emitted
2. Provides liquidity on mainnet bridge contract
2a. Bridge contract confirms the ticket
2b. Bridge contract bridges funds to appropriate L2
3. Transfer amounts + bounty fees are received by bounty seeker

**For liquidity provider**

1. Call `deposit()` on the Destination Contract to complete a transfer (minus LPfee)
2. Wait for ticket to be confirmed
3. Wait for funds to bridge
4. Call `withdraw()` on the Destination Contract to receive full amount

## Deployed Contracts

### Optimism Contracts
> On Kovan and Optimistic-Kovan

- Source : [`0xd7413Aa6A0D16b4eeA901CbC8489f065aE5FB320`](https://kovan-optimistic.etherscan.io/address/0xd7413Aa6A0D16b4eeA901CbC8489f065aE5FB320#code)
- Bridge : [`0x230e86922D90F2416239C891938DdD0078769DaF`](https://kovan.etherscan.io/address/0x230e86922D90F2416239C891938DdD0078769DaF#code)
- Destination : [`0x53fF9D8D8416497fbe1B352F509f072b276489A9`](https://kovan-optimistic.etherscan.io/address/0x53fF9D8D8416497fbe1B352F509f072b276489A9#code)

## Initializing

### Source

- `initialize()`
- `setXDomainMessenger()`
- `addDestination()`

### Destination

- `initialize()`
- `setXDomainMessenger()`

### Bridge

- `initialize()`
- `setSource()`
- `setDestination()`
- `addTokenMap()`