// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

import "../_abstract/BuddleSource.sol";

// @dev Boba is Optimism for the most part
// @dev see https://docs.boba.network/for-developers/developer-start#basics
import "@eth-optimism/contracts/L2/messaging/IL2ERC20Bridge.sol";
import "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

/**
 *
 *
 */
contract BuddleSrcBoba is BuddleSource {
    using SafeERC20 for IERC20;

    uint256 constant public CHAIN = 28; // Boba-Rinkeby
    
    address public messenger;
    address public stdBridge;

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
    * Set the addresses of Optimism's cross domain messenger
    *
    * @param _messenger Optimism L2 cross domain messenger
    * @param _stdBridge Optimism L2 standard bridge
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
    * @param _newBridgeAddress Optimism L2 standard bridge
    */
    function updateStandardBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        stdBridge = _newBridgeAddress;
    }

    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleSource
     */
    function isBridgeContract() internal view override returns (bool) {
        return (msg.sender == messenger && 
            ICrossDomainMessenger(messenger).xDomainMessageSender() == buddleBridge);
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
    ) internal override {
        IL2ERC20Bridge _bridge = IL2ERC20Bridge(stdBridge);

        for (uint n = 0; n < _tokens.length; n++) {
            if(_tokens[n] == BASE_TOKEN_ADDRESS) {
                _bridge.withdrawTo(
                    0x4200000000000000000000000000000000000006,
                    _provider,
                    _tokenAmounts[n]+_bountyAmounts[n],
                    1000000,
                    bytes("")
                );
            } else {
                _bridge.withdrawTo(
                    _tokens[n],
                    _provider,
                    _tokenAmounts[n]+_bountyAmounts[n],
                    1000000,
                    bytes("")
                );
            }
            tokenAmounts[_destChain][_tokens[n]] -= _tokenAmounts[n];
            bountyAmounts[_destChain][_tokens[n]] -= _bountyAmounts[n];
        }
    }
}