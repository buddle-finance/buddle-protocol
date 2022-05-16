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
    address tokenBridge; // The bridge deployed on the Layer-1 chain

    mapping(uint256 => address payable) liquidityOwners;
    mapping(uint256 => uint256) transferFee;
    mapping(uint => mapping(bytes32 => bool)) approvedRoot;

    event TransferCompleted(
        TransferData data,
        uint256 _id,
        address liquidityProvider
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
            && L2CrossDomainMessenger(messenger).xDomainMessageSender() == tokenBridge
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

    /* onlyOwner functions */

    function initialize(
        address _messenger,
        address _tokenBridge
    ) external onlyOwner {
        require(messenger == address(0), "contract already initialized!");
        
        messenger = _messenger;
        tokenBridge = _tokenBridge;
    }

    /* other functions */

    function changeOwner(
        TransferData memory _data,
        uint256 _transferID,
        address payable _owner
    ) external checkInitialization {
        require( (liquidityOwners[_transferID] == msg.sender) ||
            (liquidityOwners[_transferID] == address(0) && _data.destination == msg.sender),
        "You are not authorized to call this function!");
        liquidityOwners[_transferID] = _owner;
    }
    
    function deposit(
        TransferData memory transferData, 
        uint256 transferID
    ) external payable checkInitialization {
        require(liquidityOwners[transferID] == address(0), "Owner is non zero");
        
        transferFee[transferID] = getLPFee(transferData, block.timestamp);
        uint256 transferAmount = transferData.amount - transferFee[transferID];

        if (transferData.tokenAddress == BASE_TOKEN_ADDRESS) {
            require(msg.value >= transferAmount, "Not enough tokens sent");
            payable(transferData.destination).transfer(transferAmount);
        } else {
            IERC20 token = IERC20(transferData.tokenAddress);
            token.safeTransferFrom(msg.sender, transferData.destination, transferAmount);
        }
        liquidityOwners[transferID] = payable(msg.sender);

        emit TransferCompleted(transferData, transferID, liquidityOwners[transferID]);
    }

    function withdraw(
        TransferData memory transferData,
        uint256 transferID,
        bytes32 _node,
        bytes32[] memory _proof
    ) external checkInitialization {
        require( liquidityOwners[transferID] == msg.sender ||
            (liquidityOwners[transferID] == address(0) && transferData.destination == msg.sender),
            "Can only be called by owner or destination if there is no owner."
        );
        require(_verify(transferData, transferID, _node, _proof), 
            "Unknown root formed from proof"
        );

        address claimer = liquidityOwners[transferID] == address(0)? 
            transferData.destination : liquidityOwners[transferID];
        
        if(transferData.tokenAddress == BASE_TOKEN_ADDRESS) {
            require(address(this).balance >= transferData.amount,
                "Contract doesn't have enough funds yet."
            );
            payable(claimer).transfer(transferData.amount);

        } else {
            IERC20 token = IERC20(transferData.tokenAddress);
            require(token.balanceOf(address(this)) >= transferData.amount,
                "Contract doesn't have enough funds yet."
            );
            token.transferFrom(address(this), claimer, transferData.amount);
        }       
    }

    function approveStateRoot(
        uint _chain,
        bytes32 stateRoot
    ) external onlyBridgeContract checkInitialization {
        approvedRoot[_chain][stateRoot] = true;
    }

    /* internal functions */
    
    /**
     * Verify (i) The transfer data provided matches the hash provided;
     * (ii) The root formed from the node and proof is an approved root
     *
     */
    function _verify(
        TransferData memory _transferData, 
        uint256 transferID, 
        bytes32 _node,
        bytes32[] memory _proof
    ) internal view returns (bool) {

        // Check data integrity
        bytes32 transferDataHash = sha256(abi.encodePacked(
            _transferData.tokenAddress,
            _transferData.destination,
            _transferData.amount,
            _transferData.fee,
            _transferData.startTime,
            _transferData.feeRampup,
            _transferData.chain
        ));
        bytes32 node = sha256(abi.encodePacked(
            transferDataHash, 
            sha256(abi.encodePacked(address(this))),
            sha256(abi.encodePacked(transferID))
        ));
        require(node == _node, "Invalid node formed");

        // Build root
        bytes32 value = node;
        for(uint n = 0; n < _proof.length; n++) {
            if(((n / (2**n)) % 2) == 1)
                value = sha256(abi.encodePacked(_proof[n], value));
            else
                value = sha256(abi.encodePacked(value, _proof[n]));
        }
        return approvedRoot[_transferData.chain][value];
    }

    /**
     * Calculates the fees for the Liquidity Provider
     * @notice see https://notes.ethereum.org/@vbuterin/cross_layer_2_bridges
     * 
     * @param _transferData The transfer metadata of the cross chain transfer
     * @param _currentTime The current blocktime to calculate fee ramp up
     */
    function getLPFee(
        TransferData memory _transferData,
        uint256 _currentTime
    ) internal pure returns (uint256) {
        if(_currentTime < _transferData.startTime)
            return 0;
        else if(_currentTime >= _transferData.startTime + _transferData.feeRampup)
            return _transferData.fee;
        else
            return _transferData.fee * (_currentTime - _transferData.startTime); // feeRampup
    }
}
