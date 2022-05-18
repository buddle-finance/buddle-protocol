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

- Source : [`0x9E638b2C9796E5966f62a6e2d9e397aB86A89781`](https://kovan-optimistic.etherscan.io/address/0x9E638b2C9796E5966f62a6e2d9e397aB86A89781#code)
- Bridge : [`0x6eb04689C0F84553317bFE1ba221ed63F27840Cc`](https://kovan.etherscan.io/address/0x6eb04689C0F84553317bFE1ba221ed63F27840Cc#code)
- Destination : [`0x93Ef1b96F7Cea346716634eA022c920AaB772257`](https://kovan-optimistic.etherscan.io/address/0x93Ef1b96F7Cea346716634eA022c920AaB772257#code)

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