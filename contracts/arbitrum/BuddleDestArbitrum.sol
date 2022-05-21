// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../_abstract/BuddleDestination.sol";

import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";

contract BuddleDestArbitrum is BuddleDestination {

    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleDestination
     */
    function isBridgeContract() internal view override returns (bool) {
        return (AddressAliasHelper.undoL1ToL2Alias(msg.sender) == buddleBridge);
    }
}