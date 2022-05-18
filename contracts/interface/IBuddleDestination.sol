//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface IBuddleDestination {

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
        uint chain;
    }

    /**
     * Initialize the contract with state variables
     * 
     * @param _messenger Layer-2 Cross Domain messenger contract
     * @param _tokenBridge Buddle Bridge contract on Layer-1
     */
    function initialize(
        address _messenger,
        address _tokenBridge
    ) external;

    /**
     * Change the buddle bridge address
     *
     */
    function changeBuddleBridge(
        address _newBridgeAddress
    ) external;

    /**
     * Change the layer-2 cross domain messenger
     *
     */
    function changeXDomainMessenger(
        address _newMessengerAddress
    ) external;
    
    /**
     * A valid liquidity owner for a transferID may change the owner if desired
     *
     * @param _data The transfer data corresponding to the transfer id
     * @param _transferID The transfer ID corresponding to the transfer data
     * @param sourceChain The chain id of the blockchain where the transfer originated
     * @param _owner The new owner for the transfer
     */
    function changeOwner(
        TransferData memory _data,
        uint256 _transferID,
        uint sourceChain,
        address _owner
    ) external;

    /**
     * Deposit funds into the contract to transfer to the destination of the transfer.
     * If no owner exists, anyone may call this function to complete a transfer
     * and claim ownership of the LP fee
     *
     * @param transferData Transfer Data of the transfer emitted under TransferEvent
     * @param transferID Transfer ID of the transfer emitted under TransferEvent
     * @param sourceChain The chain ID for the source blockchain of transfer
     */
    function deposit(
        TransferData memory transferData, 
        uint256 transferID,
        uint sourceChain
    ) external payable;

    /**
     * This function is called under two cases,
     * (i) A LP calls this function after funds have been bridged
     * (ii) If no LP exists, the destination of the transfer calls this to claim bridged funds
     *
     * @param transferData Transfer Data of the transfer emitted under TransferCreated event
     * @param transferID Transfer ID of the transfer emitted under TransferCreated event
     * @param sourceChain The chain ID for the source blockchain of transfer
     * @param _node Hash of the transfer data emitted under TransferCreated event
     * @param _proof Path from node to root. Should be calculated offline
     * @param _root State root emitted under TicketCreated event
     */
    function withdraw(
        TransferData memory transferData,
        uint256 transferID,
        uint sourceChain,
        bytes32 _node,
        bytes32[] memory _proof,
        bytes32 _root
    ) external;

    /**
     * Approve a new root for an incoming transfer
     * @notice only the Buddle Bridge contract on Layer 1 can call this method
     *
     * @param sourceChain The chain id of the blockchain where the root originated
     * @param stateRoot The state root to be approved
     */
    function approveStateRoot(
        uint sourceChain,
        bytes32 stateRoot
    ) external;
}