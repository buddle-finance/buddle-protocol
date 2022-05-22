// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../_abstract/BuddleBridge.sol";

import "./ext/ITokenGateway.sol";
import "@arbitrum/nitro-contracts/src/bridge/Inbox.sol";
import "@arbitrum/nitro-contracts/src/bridge/IOutbox.sol";

// TODO import from package (fix incompatible solidity version issue)
// import "arb-bridge-peripherals/contracts/tokenbridge/libraries/gateway/GatewayRouter.sol";

/**
 *
 *
 */
contract BuddleBridgeArbitrum is BuddleBridge {
    using SafeERC20 for IERC20;

    uint256 constant public CHAIN = 421611; // Arbitrum-Rinkeby

    address public router;
    address public arbInbox;
    address public arbOutbox;

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
     * Initialize the contract with state variables
     *
     * @param _version Contract version
     */
    function initialize(
        bytes32 _version,
        address _gatewayRouter,
        address _arbInbox,
        address _arbOutbox
    ) external onlyOwner {
        require(bytes32(VERSION).length == 0, "Contract already initialized!");

        VERSION = _version;
        router = _gatewayRouter;
        arbInbox = _arbInbox;
        arbOutbox = _arbOutbox;
    }

    /********************
     * public functions *
     ********************/

    /**
     * @inheritdoc IBuddleBridge
     */
    function claimBounty(
        bytes32 _ticket,
        uint _chain,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256[] memory _bounty,
        uint256 _firstIdForTicket,
        uint256 _lastIdForTicket,
        bytes32 stateRoot
    ) external payable 
      checkInitialization {

        bytes memory data = abi.encodeWithSignature(
            "confirmTicket(bytes32,uint256,address[],uint256[],uint256[],uint256,uint256,bytes32,address)",
            _ticket, _chain, _tokens, _amounts, _bounty, _firstIdForTicket, _lastIdForTicket, stateRoot, msg.sender
        );

        IInbox(arbInbox).createRetryableTicket(
            buddle.source,
            0,
            1000000, // Max gas deducted from user's L2 balance to cover base submission fee
            msg.sender,
            msg.sender,
            1000000, // Max gas deducted from user's L2 balance to cover base submission fee
            0.3 * 10 ** 9, // gasPrice (in gwei)
            data
        );


        IBuddleBridge _bridge = IBuddleBridge(buddleBridge[_chain]);
        _bridge.transferFunds{value: msg.value}(_tokens, _amounts, msg.sender, _ticket);
        _bridge.approveRoot(stateRoot);

    }

    /**
     * @inheritdoc IBuddleBridge
     */
    function transferFunds(
        address[] memory _tokens,
        uint256[] memory _amounts,
        address bountySeeker,
        bytes32 _ticket
    ) external payable 
      checkInitialization
      onlyKnownBridge {
        
        // @dev see https://github.com/OffchainLabs/arbitrum/blob/master/packages/arb-bridge-peripherals/contracts/tokenbridge/ethereum/gateway/L1GatewayRouter.sol#L238
        uint256 expectedEth;
        for(uint i=0; i<_tokens.length; i++) {
            if(_tokens[i] == BASE_TOKEN_ADDRESS) {
                expectedEth += _amounts[i];
            } else {
                expectedEth += 1000000 * 3 / 10 * 10 ** 9 + 10000;
            }
        }
        require(msg.value >= expectedEth, "Insufficent ETH sent");
        // TODO uncomment above when using GatewayRouter

        ITokenGateway _router = ITokenGateway(router); // TODO change to GatewayRouter

        for(uint i=0; i < _tokens.length; i++) {
            if(_tokens[i] == BASE_TOKEN_ADDRESS) {
                require(msg.value >= _amounts[i], "Insufficient funds sent");
                // @dev see https://github.com/OffchainLabs/arbitrum/blob/78118ba205854374ed280a27415cb62c37847f72/packages/arb-bridge-eth/contracts/bridge/Inbox.sol#L247 
                // and https://github.com/OffchainLabs/arbitrum/blob/78118ba205854374ed280a27415cb62c37847f72/packages/arb-bridge-eth/contracts/bridge/Inbox.sol#L293
                Inbox(arbInbox).createRetryableTicketNoRefundAliasRewrite{value: msg.value}(
                    // destAddress
                    buddle.destination,
                    // l2 call value
                    uint256(0),
                    // maxSubmissionCost
                    1000000,
                    // excessFeeRefundAddress
                    buddle.destination,
                    // callValueRefundAddress
                    buddle.destination,
                    // maxGas
                    uint256(0),
                    // gasPriceBid
                    uint256(0),
                    // calldata data
                    bytes("")
                );
            } else {

                IERC20 token = IERC20(_tokens[i]);
                require(token.balanceOf(bountySeeker) >= _amounts[i], "Insufficient funds sent");
                
                token.safeTransferFrom(bountySeeker, address(this), _amounts[i]);
                token.approve(_router.getGateway(_tokens[i]), _amounts[i]);

                _router.outboundTransfer(
                    // l1 token address
                    tokenMap[_tokens[i]],
                    // to address
                    buddle.destination,
                    // amount
                    _amounts[i],
                    // maxGas
                    1000000,
                    // gasPriceBid
                    3 / 10 * 10 ** 9, // 0.3 Gwei
                    // calldata data
                    abi.encode(uint256(10000),bytes(""))
                );
            }
               
        }

        emit FundsBridged(CHAIN, _tokens, _amounts, block.timestamp, _ticket);
    }


    /**
     * @inheritdoc IBuddleBridge
     */
    function approveRoot(
        bytes32 _root
    ) external 
      checkInitialization
      onlyKnownBridge {

        IInbox(arbInbox).createRetryableTicket(
            buddle.destination, 
            0,
            1000000, // Max gas deducted from user's L2 balance to cover base submission fee
            msg.sender, // TODO: check if sender is contract or confirmTicket caller
            msg.sender, // TODO: check if sender is contract or confirmTicket caller
            1000000, // Max gas deducted from user's L2 balance to cover base submission fee
            3 / 10 * 10 ** 9, // gasPrice (0.3 gwei)
            abi.encodeWithSignature(
                "approveStateRoot(uint256,bytes32)",
                CHAIN, _root
            )
        );
        
    }

}