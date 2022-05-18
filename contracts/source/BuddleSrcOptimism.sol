// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../abstract/BuddleSource.sol";

import "@eth-optimism/contracts/L2/messaging/L2StandardBridge.sol";
import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";

/**
 *
 *
 */
contract BuddleSrcOptimism is BuddleSource {
    using SafeERC20 for IERC20;

    uint constant public CHAIN = 69;
    
    address messenger;
    address stdBridge;

    /* onlyOwner functions */

    /**
    * Set the addresses of Optimism's cross domain messenger
    *
    * @param _messenger Optimism L2 cross domain messenger
    * @param _stdBridge Optimism L1 standard bridge
    */
    function setXDomainMessenger(
        address _messenger,
        address _stdBridge
    ) external onlyOwner checkInitialization {
        messenger = _messenger;
        stdBridge = _stdBridge;
    }

    /**
    * Update the address of the cross domain messenger
    *
    * @param _newMessengerAddress Optimism L2 cross domain messenger
    */
    function updateXDomainMessenger(
        address _newMessengerAddress
    ) external onlyOwner checkInitialization {
        messenger = _newMessengerAddress;
    }

    /**
    * Update the address of the standard bridge
    *
    * @param _newBridgeAddress Optimism L1 standard bridge
    */
    function updateStandardBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        stdBridge = _newBridgeAddress;
    }

    /* internal functions */

    /**
     * @inheritdoc BuddleSource
     */
    function isBridgeContract() internal view override returns (bool) {
        return (msg.sender == messenger && 
            L2CrossDomainMessenger(messenger).xDomainMessageSender() == buddleBridge);
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
        uint _destChain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        uint256[] memory _bountyAmounts,
        address _provider
    ) internal override {

        // TODO: Send funds to L2 standard bridge
        for (uint n = 0; n < _tokens.length; n++) {
            if(_tokens[n] == BASE_TOKEN_ADDRESS) {
                payable(_provider).transfer(_tokenAmounts[n]+_bountyAmounts[n]);
            } else {
                IERC20 token = IERC20(_tokens[n]);
                token.safeTransfer(_provider, _tokenAmounts[n]+_bountyAmounts[n]);
            }
            tokenAmounts[_destChain][_tokens[n]] -= _tokenAmounts[n];
            bountyAmounts[_destChain][_tokens[n]] -= _bountyAmounts[n];
        }
    }
}