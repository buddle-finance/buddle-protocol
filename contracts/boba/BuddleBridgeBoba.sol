// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../_abstract/BuddleBridge.sol";

// @dev Boba is Optimism for the most part
// @dev see https://docs.boba.network/for-developers/developer-start#basics
import "@eth-optimism/contracts/L1/messaging/IL1StandardBridge.sol";
import "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

/**
 *
 *
 */
contract BuddleBridgeOptimism is BuddleBridge {
    using SafeERC20 for IERC20;

    uint256 constant public CHAIN = 28; // Boba-Rinkeby

    address public messenger;
    address public stdBridge;

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
        messenger = _messenger;
        stdBridge = _stdBridge;

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
        stdBridge = _newBridgeAddress;
    }

    /********************** 
     * public functions *
     ***********************/

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

        ICrossDomainMessenger(messenger).sendMessage(
            buddle.source,
            abi.encodeWithSignature(
                "confirmTicket(bytes32,uint256,address[],uint256[],uint256[],uint256,uint256,bytes32,address)",
                _ticket, _chain, _tokens, _amounts, _bounty, _firstIdForTicket, _lastIdForTicket, stateRoot, msg.sender
            ),
            1000000
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

        IL1StandardBridge _bridge = IL1StandardBridge(stdBridge);

        for(uint i=0; i < _tokens.length; i++) {
            if(_tokens[i] == BASE_TOKEN_ADDRESS) {
                require(msg.value >= _amounts[i], "Insufficient funds sent");
                _bridge.depositETHTo{value: msg.value}(
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

        ICrossDomainMessenger(messenger).sendMessage(
            buddle.destination,
            abi.encodeWithSignature(
                "approveStateRoot(uint256,bytes32)",
                CHAIN, _root
            ),
            1000000
        );

    }
}