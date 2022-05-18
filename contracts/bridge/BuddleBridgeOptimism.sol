// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../abstract/BuddleBridge.sol";

import "@eth-optimism/contracts/L1/messaging/L1StandardBridge.sol";
import "@eth-optimism/contracts/L1/messaging/L1CrossDomainMessenger.sol";

/**
 *
 *
 */
contract BuddleBridgeOptimism is BuddleBridge {
    using SafeERC20 for IERC20;

    uint constant public CHAIN = 69; // Optimism-Kovan

    address public messenger; // Optimism L1 cross domain messenger address
    address public l2stdBridge; // Optimism L2 standard bridge
    address public addressManager; // Optimism address manager

    /** Modifiers */

    /**
     * Checks whether the contract is initialized
     */
    modifier checkInitialization() {
        require(messenger != address(0), "Contract not initialized yet.");
        _;
    }

    /* onlyOwner functions */

    function initialize(
        address _messenger, 
        address _l2stdBridge, 
        address _addressManager
    ) external {
        require(messenger == address(0), "Contract already initialized!");

        messenger = _messenger;
        l2stdBridge = _l2stdBridge;
        addressManager = _addressManager;

        buddleBridge[CHAIN] = address(this);
        knownBridges[address(this)] = true;
    }

    function updateXDomainMessenger(
        address _newMessengerAddress
    ) external onlyOwner checkInitialization {
        messenger = _newMessengerAddress;
    }

    function updateStandardBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        l2stdBridge = _newBridgeAddress;
    }

    function updateAddressManager(
        address _newManagerAddress
    ) external onlyOwner checkInitialization {
        addressManager = _newManagerAddress;
    }

    /* public functions */

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

        L1CrossDomainMessenger _messenger;
        _messenger.initialize(addressManager);

        _messenger.sendMessage(
            buddle.source,
            abi.encodeWithSignature(
                "confirmTicket(bytes32, uint, address[], uint256[], uint256[], uint256, uint256, bytes32, address)",
                _ticket, _chain, _tokens, _amounts, _bounty, _firstIdForTicket, _lastIdForTicket, stateRoot, msg.sender
            ),
            1000000
        );

        IBuddleBridge _bridge = IBuddleBridge(buddleBridge[_chain]);
        _bridge.transferFunds{value: msg.value}(_tokens, _amounts, msg.sender);
        _bridge.approveRoot(stateRoot);

    }

    function transferFunds(
        address[] memory _tokens,
        uint256[] memory _amounts,
        address bountySeeker
    ) external payable 
      checkInitialization
      onlyKnownBridge {

        L1StandardBridge _bridge;
        _bridge.initialize(messenger, l2stdBridge);

        for(uint i=0; i < _tokens.length; i++) {
            if(_tokens[i] == BASE_TOKEN_ADDRESS) {
                require(msg.value >= _amounts[i], "Insufficient funds sent");
                _bridge.depositETHTo(
                    buddle.destination, 
                    1000000, 
                    bytes("")
                );
            } else {
                IERC20 token = IERC20(_tokens[i]);
                require(token.balanceOf(bountySeeker) >= _amounts[i], "Insufficient funds sent");
                
                token.safeTransferFrom(bountySeeker, address(this), _amounts[i]);
                token.approve(messenger, _amounts[i]);
                
                _bridge.depositERC20To(
                    tokenMap[_tokens[i]], // L1 token address
                    _tokens[i], // L2 token address
                    buddle.destination, // to address
                    _amounts[i], // amount to be transferred
                    1000000, // Gas limit 
                    bytes("") // Data empty
                );
            }
        }

    }

    function approveRoot(
        bytes32 _root
    ) external 
      checkInitialization
      onlyKnownBridge {

        L1CrossDomainMessenger _messenger;
        _messenger.initialize(addressManager);

        _messenger.sendMessage(
            buddle.destination,
            abi.encodeWithSignature(
                "approveStateRoot(uint, bytes32)",
                CHAIN, _root
            ),
            1000000
        );

    }
}