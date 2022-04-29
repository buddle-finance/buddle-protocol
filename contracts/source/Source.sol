//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract Source is Ownable {
    using SafeERC20 for IERC20;

    uint constant public MERKLE_TREE_DEPTH = 16;
    uint constant public MAX_DEPOSIT_COUNT = 2 ** MERKLE_TREE_DEPTH - 1;
    bytes32[MERKLE_TREE_DEPTH] private branch;
    bytes32[MERKLE_TREE_DEPTH] private zeroes;
    
    uint256 public CONTRACT_FEE_BASIS_POINTS;
    uint256 public feeRampUp;

    uint256 public nextTransferID;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public bountyPool;

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
    }

    event TransferInitiated(TransferData data, Source self, uint256 nextTransferID);
    // event

    function initialize(uint256 _feeRampUp, uint256 _freeBasisPoints) public onlyOwner {
        CONTRACT_FEE_BASIS_POINTS = _freeBasisPoints;
        feeRampUp = _feeRampUp;

        for (uint height = 0; height < MERKLE_TREE_DEPTH - 1; height++)
            zeroes[height + 1] = sha256(abi.encodePacked(zeroes[height], zeroes[height]));
    }

    function widthdraw(address _tokenAddress, address _destination, uint256 _amount) public payable {

        uint256 amountPlusFee = (_amount * (10000 + CONTRACT_FEE_BASIS_POINTS)) / 10000;

        TransferData memory data;
        data.tokenAddress = _tokenAddress;
        data.destination = _destination;
        data.amount = _amount;
        data.fee = amountPlusFee - data.amount;
        data.startTime = block.timestamp;
        data.feeRampup = feeRampUp;

        if (data.tokenAddress == address(0)) {
            require(msg.value == amountPlusFee, "Insufficient amount");
        } else {
            IERC20 token = IERC20(data.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amountPlusFee);
        }
        
        bytes32 transferDataHash = sha256(abi.encodePacked(data.tokenAddress, data.destination, data.amount, data.fee, data.startTime, data.feeRampup));
        bytes32 contractHash = sha256(abi.encodePacked(address(this)));
        bytes32 nextTransferIDHash = sha256(abi.encodePacked(nextTransferID));

        bytes32 node = sha256(abi.encodePacked(transferDataHash, contractHash, nextTransferIDHash));

        nextTransferID += 1;
        updateMerkle(node);
        
        emit TransferInitiated(data, this, nextTransferID);
        

    }

    function updateMerkle(bytes32 _node) public {
        uint size = nextTransferID % MAX_DEPOSIT_COUNT;
        for (uint depth = 0; depth < MERKLE_TREE_DEPTH; depth++) {

            if ((size & 1) == 1) {
                branch[depth] = _node;
                return;
            }

            _node = sha256(abi.encodePacked(branch[depth], _node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }


    function changeContractFeeBasisPoints(uint256 newContractFeeBasisPoints) public onlyOwner {
        CONTRACT_FEE_BASIS_POINTS = newContractFeeBasisPoints;
    }

    function changeContractFeeRampUp(uint256 newContractFeeRampUp) public onlyOwner {
        feeRampUp = newContractFeeRampUp;
    }
}

