// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.11;

import "../_abstract/BuddleSource.sol";

import { FxStateChildTunnel } from "./FxStateChildTunnel.sol";
import { IFxMessageProcessor } from "./ext/FXBaseChildTunnel.sol";


/**
 *
 *
 */
contract BuddleSrcPolygon is BuddleSource {
    using SafeERC20 for IERC20;

    uint256 constant public CHAIN = 80001; // Polygon mumbai
    address public stdBridge;

    IFxMessageProcessor public fxChildTunnel;

    bool public isInitiated = false;

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
    * Deploy new instance of FxStateChildTunnel and initialize contract
    *
    * @param _fxChild Polygon FxBaseChildTunnel address
    */
    function setBuddleSrcPolygon(address _fxChild) external checkInitialization onlyOwner {
        require(isInitiated == false, "Already initiated");
        fxChildTunnel = new FxStateChildTunnel(_fxChild);
        isInitiated = true;
    }

    function modifyFxStateChildTunnel(address _fxChild) external onlyOwner {
        fxChildTunnel = _fxChild;
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
        return (msg.sender == address(fxChildTunnel));
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
                    0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000,
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