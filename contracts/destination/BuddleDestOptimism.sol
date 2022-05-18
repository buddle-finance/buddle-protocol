// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interface/IBuddleDestination.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";

contract BuddleDestOptimism is IBuddleDestination, Ownable {
    using SafeERC20 for IERC20;

    address constant BASE_TOKEN_ADDRESS = address(0);

    address messenger; // Address of deployed L2CrossDomainMessenger contract on Optimism
    address buddleBridge; // The bridge deployed on the Layer-1 chain

    mapping(uint => mapping(uint256 => address)) public liquidityOwners;
    mapping(uint => mapping(bytes32 => bool)) public liquidityHashes;
    mapping(uint => mapping(uint256 => uint256)) public transferFee;
    mapping(uint => mapping(bytes32 => bool)) public approvedRoot;

    /* events */

    event TransferCompleted(
        TransferData transferData,
        uint256 transferID,
        uint sourceChain,
        address liquidityProvider
    );

    event WithdrawalEvent(
        TransferData transferData,
        uint256 transferID,
        uint sourceChain,
        address claimer
    );


    /* modifiers */

    /**
     * Checks whether the message sender is the L2 messenger contract
     * and whether the message originated from the deployed L1 token bridge
     *
     */
    modifier onlyBridgeContract() {
        require(
            msg.sender == address(messenger)
            && L2CrossDomainMessenger(messenger).xDomainMessageSender() == buddleBridge
        );
        _;
    }


    /**
     * Checks whether the contract is initialized
     *
     */
    modifier checkInitialization() {
        require(messenger != address(0), "Contract not yet initialzied");
        _;
    }

    /**
     * Checks that the caller is either the owner of liquidity or the destination of a transfer
     *
     */
    modifier validOwner(
        uint sourceChain,
        uint256 _id,
        address _destination
    ) {
        require( liquidityOwners[sourceChain][_id] == msg.sender ||
            (liquidityOwners[sourceChain][_id] == address(0) && _destination == msg.sender),
            "Can only be called by owner or destination if there is no owner."
        );
        _;
    }

    /* onlyOwner functions */

    function initialize(
        address _messenger,
        address _buddleBridge
    ) external onlyOwner {
        require(messenger == address(0), "contract already initialized!");
        
        messenger = _messenger;
        buddleBridge = _buddleBridge;
    }

    function changeBuddleBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        buddleBridge = _newBridgeAddress;
    }

    function changeXDomainMessenger(
        address _newMessengerAddress
    ) external onlyOwner checkInitialization {
        messenger = _newMessengerAddress;
    }

    /* other functions */

    function changeOwner(
        TransferData memory _data,
        uint256 _transferID,
        uint sourceChain,
        address _owner
    ) external 
      checkInitialization
      validOwner(sourceChain, _transferID, _data.destination) {
        liquidityOwners[sourceChain][_transferID] = _owner;
    }
    
    function deposit(
        TransferData memory transferData, 
        uint256 transferID,
        uint sourceChain
    ) external payable checkInitialization {
        require(liquidityOwners[sourceChain][transferID] == address(0),
            "A Liquidity Provider already exists for this transfer"
        );
        
        transferFee[sourceChain][transferID] = getLPFee(transferData, block.timestamp);
        uint256 amountMinusLPFee = transferData.amount - transferFee[sourceChain][transferID];

        if (transferData.tokenAddress == BASE_TOKEN_ADDRESS) {
            require(msg.value >= amountMinusLPFee, "Not enough tokens sent");
            payable(transferData.destination).transfer(amountMinusLPFee);
        } else {
            IERC20 token = IERC20(transferData.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amountMinusLPFee);
            token.safeTransfer(transferData.destination, amountMinusLPFee);
        }
        liquidityOwners[sourceChain][transferID] = msg.sender;
        liquidityHashes[sourceChain][_generateNode(transferData, transferID)] = true;

        emit TransferCompleted(transferData, transferID, sourceChain, msg.sender);
    }

    function withdraw(
        TransferData memory transferData,
        uint256 transferID,
        uint sourceChain,
        bytes32 _node,
        bytes32[] memory _proof,
        bytes32 _root
    ) external 
      checkInitialization
      validOwner(sourceChain, transferID, transferData.destination) {

        require(_verifyNode(transferData, transferID, _node), "Invalid node fromed");
        require(_verifyProof(_node, _proof, _root), "Invalid root formed from proof");
        require(approvedRoot[sourceChain][_root], "Unknown root provided");

        // Check if hashed node is known in case of owner existance
        // ie, if the deposit() transferData does not match withdraw() transferData
        //  reset liquidity owner for the transfer id
        if(liquidityOwners[sourceChain][transferID] != address(0)
            && !liquidityHashes[sourceChain][_node]) {
            liquidityOwners[sourceChain][transferID] = address(0);
        }

        address claimer = liquidityOwners[sourceChain][transferID] == address(0)? 
            transferData.destination : liquidityOwners[sourceChain][transferID];
        
        if(transferData.tokenAddress == BASE_TOKEN_ADDRESS) {
            require(address(this).balance >= transferData.amount,
                "Contract doesn't have enough funds yet."
            );
            payable(claimer).transfer(transferData.amount);

        } else {
            IERC20 token = IERC20(transferData.tokenAddress);
            token.safeTransferFrom(address(this), claimer, transferData.amount);
        }

        liquidityOwners[sourceChain][transferID] = address(this);
        liquidityHashes[sourceChain][_node] = false;

        emit WithdrawalEvent(transferData, transferID, sourceChain, claimer);
    }

    function approveStateRoot(
        uint sourceChain,
        bytes32 stateRoot
    ) external onlyBridgeContract checkInitialization {
        approvedRoot[sourceChain][stateRoot] = true;
    }

}
