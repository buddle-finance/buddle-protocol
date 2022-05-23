// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../_abstract/BuddleDestination.sol";

import "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

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
     * @param _newMessenger Layer-2 Cross Domain messenger contract
     */
    function updateXDomainMessenger(
        address _newMessenger
    ) external onlyOwner checkInitialization {
        messenger = _newMessenger;
    }

    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleDestination
     */
    function isBridgeContract() internal view override returns (bool) {
        return (msg.sender == messenger && 
            ICrossDomainMessenger(messenger).xDomainMessageSender() == buddleBridge);
    }
}
