//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract Source is Ownable {
    using SafeERC20 for IERC20;

    uint256 public nextTransferID;
    uint256 public CONTRACT_FEE_BASIS_POINTS;
    uint256 public feeRampUp;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public bountyPool;
    address[] public nonZeroBalanceTokens;

    

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
    }

    constructor() {
        CONTRACT_FEE_BASIS_POINTS = 5;
        feeRampUp = 1;
    }



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

    function changeContractFeeBasisPoints(uint256 newContractFeeBasisPoints) public onlyOwner {
        CONTRACT_FEE_BASIS_POINTS = newContractFeeBasisPoints;
    }

    function changeContractFeeRampUp(uint256 newContractFeeRampUp) public onlyOwner {
        feeRampUp = newContractFeeRampUp;
    }
}


contract TestMerkleProof is MerkleProof {
    bytes32[] public hashes;

    constructor() {
        string[4] memory transactions = [
            "0x678eajdjsufu678",
            "bob -> dave",
            "carol -> alice",
            "dave -> bob"
        ];

        for (uint i = 0; i < transactions.length; i++) {
            hashes.push(keccak256(abi.encodePacked(transactions[i])));
        }

        uint n = transactions.length; // 4
        uint offset = 0; 

        while (n > 0) {
            for (uint i = 0; i < n - 1; i += 2) {
                hashes.push(
                    keccak256(
                        abi.encodePacked(hashes[offset + i], hashes[offset + i + 1])
                    )
                );
            }
            offset += n;
            n = n / 2;
        }
    }

    function getRoot() public view returns (bytes32) {
        return hashes[hashes.length - 1];
    }

    /* verify
    3rd leaf
    0x1bbd78ae6188015c4a6772eb1526292b5985fc3272ead4c65002240fb9ae5d13

    root
    0x074b43252ffb4a469154df5fb7fe4ecce30953ba8b7095fe1e006185f017ad10

    index
    2

    proof
    0x948f90037b4ea787c14540d9feb1034d4a5bc251b9b5f8e57d81e4b470027af8
    0x63ac1b92046d474f84be3aa0ee04ffe5600862228c81803cce07ac40484aee43
    */
}

