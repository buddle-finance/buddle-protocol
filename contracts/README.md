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