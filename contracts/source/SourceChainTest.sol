function withdraw(address tokenAddress, address destination, uint256 amount) public payable {
        TransferData memory data;
        data.tokenAddress = tokenAddress;
        data.destination = destination;
        data.amount = amount;

        uint256 amountPlusFee = (data.amount * (10000 + CONTRACT_FEE_BASIS_POINTS)) / 10000;
        data.fee = amountPlusFee - data.amount;
        
        IERC20 sourceToken;
        if (data.tokenAddress == address(0)) {
            require(msg.value == amountPlusFee, "Incorrect amount");
            // TODO Check if ETH is available on destination
        } else {
            sourceToken = IERC20(data.tokenAddress);
            sourceToken.safeTransferFrom(msg.sender, address(this), amountPlusFee);
            // TODO Check if token is available on destination
        }

        data.startTime = block.timestamp;
        data.feeRampup = feeRampUp;
        
        uint prevBalance = bountyPool[data.tokenAddress];
        bountyPool[data.tokenAddress] += data.fee;
        balances[data.tokenAddress] += data.amount;

        if (prevBalance == 0) {
            nonZeroBalanceTokens.push(data.tokenAddress);
        }
        // TODO Remove element from array and reset balance and bounty for token when moveToDestination is triggered

        // Using Markle proof, Create a TransferInitiated(transfer, self,nextTransferID) record and save it in a Merkle tree
        

        nextTransferID += 1;

    }