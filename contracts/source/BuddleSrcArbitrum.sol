// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../abstract/BuddleSource.sol";

import "../ext/arbitrum/ITokenGateway.sol";
import "@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";

/**
 *
 *
 */
contract BuddleSrcArbitrum is BuddleSource {

    uint256 constant public CHAIN = 421611; // Arbitrum-Rinkeby

    address public arbSys;
    address public router;

    mapping(address => address) public l1TokenMap; 

    /********************** 
     * onlyOwner functions *
     ***********************/
    
    function setXDomainMessenger(
        address _arbSys,
        address _gatewayRouter
    ) external onlyOwner checkInitialization {
        arbSys = _arbSys;
        router = _gatewayRouter;
    }

    function updateArbSys(address _arbSys) external {
        arbSys = _arbSys;
    }

    function updateGatewayRouter(address _gatewayRouter) external {
        router = _gatewayRouter;
    }

    function addL1Token(
        address _l1Token,
        address _l2Token
    ) external onlyOwner {
        require(tokenMapping[_l2Token], "L2 token address unknown to contract");
        l1TokenMap[_l2Token] = _l1Token;
    }

    function updateL1Token(
        address _l1Token,
        address _l2Token
    ) external onlyOwner {
        require(l1TokenMap[_l2Token] != address(0), "Token never stored in contract");
        l1TokenMap[_l2Token] = _l1Token;
    }


    /********************** 
     * internal functions *
     ***********************/

    /**
     * @inheritdoc BuddleSource
     */
    function isBridgeContract() internal view override returns (bool) {
        return (AddressAliasHelper.undoL1ToL2Alias(msg.sender) == buddleBridge);
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

        ITokenGateway _router = ITokenGateway(router); // TODO change to GatewayRouter

        for (uint n = 0; n < _tokens.length; n++) {
            if(_tokens[n] == BASE_TOKEN_ADDRESS) {
                ArbSys(arbSys).withdrawEth{value: _tokenAmounts[n]+_bountyAmounts[n]}(_provider);
            } else {
                // _router.outboundTransfer(
                //     l1TokenMap[_tokens[n]],
                //     _provider,
                //     _tokenAmounts[n]+_bountyAmounts[n],
                //     1000000,
                //     3 / 10 * 10 ** 9, // 0.3 Gwei
                //     bytes("")
                // );
            }
            tokenAmounts[_destChain][_tokens[n]] -= _tokenAmounts[n];
            bountyAmounts[_destChain][_tokens[n]] -= _bountyAmounts[n];
        }
    }
}