// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../_abstract/BuddleDestination.sol";

contract BuddleDestZkSync is BuddleDestination {

    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleDestination
     */
    function isBridgeContract() internal view override returns (bool) {
        return msg.sender == buddleBridge;
    }
}
