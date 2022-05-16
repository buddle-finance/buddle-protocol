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
     * @param _messenger Optimism's Layer-2 Cross Domain messenger contract
     * @param _tokenBridge Optimism's Layer-2 Standard Token Bridge contract
     */
    function initialize(
        address _messenger,
        address _tokenBridge
    ) external;

    /// @notice buy function
    /// @notice if the owner is zero, anyone can call this function paying the required tokens
    /// @notice and claiming ownership
    /**
     *
     *
     */
    function deposit(
        TransferData memory transferData, 
        uint256 transferID
    ) external payable;

    /// @notice withdraw function
    /// @notice if the contract has enough balance, the owner(or the destination if the owner is zero)
    /// @notice can call this function, the function will confirm the transfer with the state root
    /// @notice and if the transfer is confirmed, the transfer value will be transfered to the 
    /// @notice destination address
    /// @param _proof should be calculated offline
    /**
     *
     *
     */
    function withdraw(
        TransferData memory transferData,
        uint256 transferID,
        bytes32 _node,
        bytes32[] memory _proof
    ) external;

    /**
     * Approve a new root for an incoming transfer
     * @notice only the Buddle Bridge contract on Layer 1 can call this method
     *
     */
    function approveStateRoot(
        uint _chain,
        bytes32 stateRoot
    ) external;
}