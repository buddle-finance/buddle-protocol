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
    
    address messenger;  // L2 blockchain cross domain messenger contract address
    address stdBridge; // L1 Standard bridge for Optimism

    /* onlyOwner functions */

    function setXDomainMessenger(
        address _messenger,
        address _stdBridge
    ) external onlyOwner checkInitialization {
        messenger = _messenger;
        stdBridge = _stdBridge;
    }

    function updateXDomainMessenger(
        address _newMessengerAddress
    ) external onlyOwner checkInitialization {
        messenger = _newMessengerAddress;
    }

    function updateStandardBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        stdBridge = _newBridgeAddress;
    }

    /* internal functions */

    function isBridgeContract() internal view override returns (bool) {
        return (msg.sender == messenger && 
            L2CrossDomainMessenger(messenger).xDomainMessageSender() == buddleBridge);
    }

    function _emitTransfer(
        TransferData memory _data,
        uint256 _id,
        bytes32 _node
    ) internal override {
        emit TransferStarted(_data, _id, _node, CHAIN);
    }

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