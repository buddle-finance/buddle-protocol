// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

import "../_abstract/BuddleSource.sol";

import "@matterlabs/zksync-contracts/contracts/interfaces/IZkSync.sol";
import "@matterlabs/zksync-contracts/contracts/libraries/Operations.sol";

/**
 *
 *
 */
contract BuddleSrcZkSync is BuddleSource {
    using SafeERC20 for IERC20;

    uint256 constant public CHAIN = 280;
    
    address public zkSyncAddress;

    /***********************
     * onlyOwner functions *
     ***********************/

    /**
    * Set the addresses of the zkSync contract
    *
    * @param _zkSyncAddress zkSync contract address
    */
    function setZkSyncAddress(
        address _zkSyncAddress
    ) external onlyOwner checkInitialization {
        zkSyncAddress = _zkSyncAddress;
    }

    /**
    * Update the address of the zkSync contract
    *
    * @param _newZkSyncAddress zkSync contract address
    */
    function updateZkSyncAddress(
        address _newZkSyncAddress
    ) external onlyOwner checkInitialization {
        zkSyncAddress = _newZkSyncAddress;
    }

    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleSource
     */
    function isBridgeContract() internal view override returns (bool) {
        return msg.sender == buddleBridge;
    }

    /**
     * @inheritdoc BuddleSource
     */
    function _emitTransfer(
        TransferData memory _data,
        uint256 _id,
        bytes32 _node
    ) internal override {
        emit TransferStarted(_data, _id, _node, CHAIN);
    }

    /**
     * @inheritdoc BuddleSource
     */
    function _bridgeFunds(
        uint256 _destChain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        uint256[] memory _bountyAmounts,
        address _provider
    ) internal payable override {
        IZkSync zksync = IZkSync(zkSyncAddress);

        // TODO: msg.value returns 0 on zk. Check this and fix
        // uint256 baseCost = zksync.withdrawBaseCost(tx.gasprice, Operations.QueueType.Deque, Operations.OpTree.Full);
        // require (baseCost <= msg.value, "Not enough funds to pay for base cost");
        for (uint n = 0; n < _tokens.length; n++) {
            if(_tokens[n] == BASE_TOKEN_ADDRESS) {
                zksync.requestWithdraw{value: msg.value} (
                    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                    _tokenAmounts[n]+_bountyAmounts[n],
                    _provider,
                    Operations.QueueType.Deque,
                    Operations.OpTree.Full
                );
            } else {
                zksync.requestWithdraw{value: msg.value} (
                    _tokens[n],
                    _tokenAmounts[n]+_bountyAmounts[n],
                    _provider,
                    Operations.QueueType.Deque,
                    Operations.OpTree.Full
                );
            }
            tokenAmounts[_destChain][_tokens[n]] -= _tokenAmounts[n];
            bountyAmounts[_destChain][_tokens[n]] -= _bountyAmounts[n];
        }
    }
}