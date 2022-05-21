// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../abstract/BuddleBridge.sol";

import "@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import "@arbitrum/nitro-contracts/src/bridge/IInbox.sol";
import "@arbitrum/nitro-contracts/src/bridge/IOutbox.sol";

/**
 *
 *
 */
contract BuddleBridgeArbitrum is BuddleBridge {
    using SafeERC20 for IERC20;

    uint256 constant public CHAIN = 421611; // Arbitrum-Rinkeby

    address public arbInbox;
    address public arbOutbox;

    /*************
     * modifiers *
     *************/

    /**
     * Checks whether the contract is initialized
     */
    modifier checkInitialization() {
        require(bytes32(VERSION).length > 0, "Contract not initialized yet.");
        _;
    }
    
    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
     * Initialize the contract with state variables
     *
     * @param _version Contract version
     * @param _messenger The address of the L1 Cross Domain Messenger Contract
     * @param _stdBridge The address of the L1 Standard Token Bridge
     */
    function initialize(
        bytes32 _version,
        address _messenger,
        address _stdBridge
    ) external onlyOwner {
        require(bytes32(VERSION).length == 0, "Contract already initialized!");

        VERSION = _version;
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

        IInbox(arbInbox).createRetryableTicket(
            buddle.source,
            0,
            1000000, // Max gas deducted from user's L2 balance to cover base submission fee
            msg.sender,
            msg.sender,
            1000000, // Max gas deducted from user's L2 balance to cover base submission fee
            0.3 * 10 ** 9, // gasPrice (in gwei)
            abi.encodeWithSignature(
                "confirmTicket(bytes32,uint256,address[],uint256[],uint256[],uint256,uint256,bytes32,address)",
                _ticket, _chain, _tokens, _amounts, _bounty, _firstIdForTicket, _lastIdForTicket, stateRoot, msg.sender
            )
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

        for(uint i=0; i < _tokens.length; i++) {
            if(_tokens[i] == BASE_TOKEN_ADDRESS) {
                require(msg.value >= _amounts[i], "Insufficient funds sent");
                // TODO specify destination address
                IInbox(arbInbox).depositEth{value: msg.value}(100000);
            } else {
                IERC20 token = IERC20(_tokens[i]);
                require(token.balanceOf(bountySeeker) >= _amounts[i], "Insufficient funds sent");
                
                token.safeTransferFrom(bountySeeker, address(this), _amounts[i]);
                token.approve(messenger, _amounts[i]);

                // TODO GatewayRouter.outBoundTransfer
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
            0.3 * 10 ** 9, // gasPrice (in gwei)
            abi.encodeWithSignature(
                "approveStateRoot(uint256,bytes32)",
                CHAIN, _root
            )
        );
        
    }

}