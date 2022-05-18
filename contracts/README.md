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

**Optimsim Kovan Source** 0xf65D533246e28Ccde202a446271FC5f0Fc1b9A29
**Optimsim Kovan Destination** 0xB3eeb48D47D7361A329B0337C47ebDcc18901A0c

**Kovan Bridge** 0x3ec618E37e00E19bc2b139D0C3aa02feFe692E28

### Optimism Contracts

- Source : `[](https://kovan-optimistic.etherscan.io/address/#code)`
- Bridge : `[](https://kovan-optimistic.etherscan.io/address/#code)`
- Destination : `[](https://kovan-optimistic.etherscan.io/address/#code)`