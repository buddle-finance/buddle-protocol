// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interface/IBuddleDestination.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 *
 */
abstract contract BuddleDestination is IBuddleDestination, Ownable {
    using SafeERC20 for IERC20;

    bytes32 public VERSION;
    address constant BASE_TOKEN_ADDRESS = address(0);

    address public buddleBridge;

    mapping(uint256 => mapping(uint256 => address)) public liquidityOwners;
    mapping(uint256 => mapping(uint256 => uint256)) public transferFee;
    mapping(uint256 => mapping(bytes32 => bool)) internal liquidityHashes;
    mapping(uint256 => mapping(bytes32 => bool)) internal approvedRoot;

    /********** 
     * events *
     **********/

    event TransferCompleted(
        TransferData transferData,
        uint256 transferID,
        uint256 sourceChain,
        address liquidityProvider
    );

    event WithdrawalEvent(
        TransferData transferData,
        uint256 transferID,
        uint256 sourceChain,
        address claimer
    );

    event LiquidityOwnerChanged(
        uint256 sourceChain,
        uint256 transferID,
        address oldOwner,
        address newOwner
    );

    event RootApproved(
        uint256 sourceChain,
        bytes32 stateRoot
    );

    /************
     * modifers *
     ************/
    
    /**
     * Checks whether the contract is initialized
     *
     */
    modifier checkInitialization() {
        require(bytes32(VERSION).length > 0, "Contract not yet initialzied");
        _;
    }

    /**
     * Checks that the caller is either the owner of liquidity or the destination of a transfer
     *
     */
    modifier validOwner(
        uint256 sourceChain,
        uint256 _id,
        address _destination
    ) {
        require( liquidityOwners[sourceChain][_id] == msg.sender ||
            (liquidityOwners[sourceChain][_id] == address(0) && _destination == msg.sender),
            "Can only be called by owner or destination if there is no owner."
        );
        _;
    }

    /********************** 
     * virtual functions *
     ***********************/
    
    /**
    * Returns true if the msg.sender is the buddleBridge contract address
    *
    */
    function isBridgeContract() internal virtual returns (bool);

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
     * Initialize the contract with state variables
     * 
     * @param _version Contract version
     * @param _buddleBridge Buddle Bridge contract on Layer-1
     */
    function initialize(
        bytes32 _version,
        address _buddleBridge
    ) external onlyOwner {
        require(bytes32(VERSION).length == 0, "contract already initialized!");
        
        VERSION = _version;
        buddleBridge = _buddleBridge;
    }

    /**
     * @inheritdoc IBuddleDestination
     */
    function updateBuddleBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        buddleBridge = _newBridgeAddress;
    }
    
    /********************** 
     * public functions *
     ***********************/
    
    /**
     * @inheritdoc IBuddleDestination
     */
    function changeOwner(
        TransferData memory _data,
        uint256 _transferID,
        uint256 sourceChain,
        address _owner
    ) external 
      checkInitialization
      validOwner(sourceChain, _transferID, _data.destination) {
        address _old = liquidityOwners[sourceChain][_transferID] == address(0)?
            _data.destination : liquidityOwners[sourceChain][_transferID];
        liquidityOwners[sourceChain][_transferID] = _owner;
        
        emit LiquidityOwnerChanged(sourceChain, _transferID, _old, _owner);
    }

    /**
     * @inheritdoc IBuddleDestination
     */
    function deposit(
        TransferData memory transferData, 
        uint256 transferID,
        uint256 sourceChain
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

    /**
     * @inheritdoc IBuddleDestination
     */
    function withdraw(
        TransferData memory transferData,
        uint256 transferID,
        uint256 sourceChain,
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

    /**
     * @inheritdoc IBuddleDestination
     */
    function approveStateRoot(
        uint256 sourceChain,
        bytes32 stateRoot
    ) external checkInitialization {
        require(isBridgeContract(), "Only the Buddle Bridge contract can call this method");
        
        approvedRoot[sourceChain][stateRoot] = true;

        emit RootApproved(sourceChain, stateRoot);
    }

    /********************** 
     * internal functions *
     ***********************/

    /**
     * Generate a hash node with the given transfer data and transfer id
     *
     * @param _transferData Transfer Data of the transfer emitted under TransferCreated event
     * @param transferID Transfer ID of the transfer emitted under TransferCreated event
     */
    function _generateNode(
        TransferData memory _transferData, 
        uint256 transferID
    ) internal view returns (bytes32 node) {
        bytes32 transferDataHash = sha256(abi.encodePacked(
            _transferData.tokenAddress,
            _transferData.destination,
            _transferData.amount,
            _transferData.fee,
            _transferData.startTime,
            _transferData.feeRampup,
            _transferData.chain
        ));
        node = sha256(abi.encodePacked(
            transferDataHash, 
            sha256(abi.encodePacked(address(this))), // TODO: this line may cause an error
            sha256(abi.encodePacked(transferID))
        ));
    }

    /**
     * Verify that the transfer data provided matches the hash provided
     *
     */
    function _verifyNode(
        TransferData memory _transferData, 
        uint256 transferID, 
        bytes32 _node
    ) internal view returns (bool) {
        return _generateNode(_transferData, transferID) == _node;
    }
    
    /**
     * Verify that the root formed from the node and proof is the provided root
     *
     */
    function _verifyProof(
        bytes32 _node,
        bytes32[] memory _proof,
        bytes32 _root
    ) internal pure returns (bool) {
        bytes32 value = _node;
        for(uint n = 0; n < _proof.length; n++) {
            if(((n / (2**n)) % 2) == 1)
                value = sha256(abi.encodePacked(_proof[n], value));
            else
                value = sha256(abi.encodePacked(value, _proof[n]));
        }
        return (value == _root);
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
        else if(_currentTime >= _transferData.startTime + _transferData.feeRampup) // TODO check logic
            return _transferData.fee;
        else
            return _transferData.fee * (_currentTime - _transferData.startTime); // feeRampup
    }
}