// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../abstract/BuddleDestination.sol";

import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";

contract BuddleDestOptimism is BuddleDestination {

    address public messenger;

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
     * Change the layer-2 cross domain messenger
     *
     * @param _messenger Layer-2 Cross Domain messenger contract
     */
    function setXDomainMessenger(
        address _messenger
    ) external onlyOwner checkInitialization {
        messenger = _messenger;
    }

    /**
     * Change the layer-2 cross domain messenger
     *
     * @param _newMessengerAddress Layer-2 Cross Domain messenger contract
     */
    function updateXDomainMessenger(
        address _newMessengerAddress
    ) external onlyOwner checkInitialization {
        messenger = _newMessengerAddress;
    }

    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleDestination
     */
    function isBridgeContract() internal view override returns (bool) {
        return (msg.sender == messenger && 
            L2CrossDomainMessenger(messenger).xDomainMessageSender() == buddleBridge);
    }

    /**
     * Generate a hash node 
     *
     */
    function _generateNode(
        TransferData memory _transferData, 
        uint256 transferID
    ) internal view override returns (bytes32 node) {
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
            sha256(abi.encodePacked(address(this))), // this line is why this method is here
            sha256(abi.encodePacked(transferID))
        ));
    }
}
