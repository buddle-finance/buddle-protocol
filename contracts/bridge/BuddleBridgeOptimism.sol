// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interface/IBuddleBridge.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@eth-optimism/contracts/L1/messaging/L1StandardBridge.sol";
import "@eth-optimism/contracts/L1/messaging/L1CrossDomainMessenger.sol";


contract BuddleBridgeOptimism is IBuddleBridge, Ownable {
    using SafeERC20 for IERC20;

    address constant BASE_TOKEN_ADDRESS = address(0);
    uint constant public CHAIN = 69; // Optimism-Kovan

    address messenger; // Optimism L1 cross domain messenger address
    address tokenBridge; // Optimism L2 standard bridge
    address addressManager; // Optimism address manager

    address srcContract; // Address of deployed Source Side contract on Optimism
    address destContract; // Address of deployed Destination Side contract on Optimism

    mapping(address => address) tokenMap; // l2 token address => l1 token address
    mapping(uint => address) buddleBridge; // Chain ID => Buddle Bridge Contract Address

    /** Modifiers */

    /**
     * Checks that _source is not already mapped
     */
    modifier emptyPair(address _l2TokenAddr) {
        require(tokenMap[_l2TokenAddr] == address(0), "Source is already paired!");
        _;
    }

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
        address _tokenBridge, 
        address _addressManager
    ) external {
        require(messenger == address(0), "Contract already initialized!");
        messenger = _messenger;
        tokenBridge = _tokenBridge;
        addressManager = _addressManager;
    }

    function setContracts(
        address _src,
        address _dest
    ) external onlyOwner checkInitialization {
        srcContract = _src;
        destContract = _dest;
    }

    function addTokenAddress(
        address _l2TokenAddress,
        address _l1TokenAddress 
    ) external onlyOwner emptyPair(_l2TokenAddress) checkInitialization {
        tokenMap[_l2TokenAddress] = _l1TokenAddress;
    }

    /* other functions */

    function claimBounty(
        bytes32 _ticket,
        uint _chain,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _firstIdForTicket,
        uint256 _lastIdForTicket,
        bytes32 stateRoot
    ) external payable {
        L1CrossDomainMessenger _messenger;
        _messenger.initialize(addressManager);

        _messenger.sendMessage(
            srcContract,
            abi.encodeWithSignature(
                "confirmTicket(bytes32, uint, address[], uint256[], uint256, uint256, bytes32, address)",
                _ticket, _chain, _tokens, _amounts, _firstIdForTicket, _lastIdForTicket, stateRoot, msg.sender
            ),
            1000000
        );

        if (_chain == CHAIN) {
            transferFunds(_tokens, _amounts);
            approveRoot(stateRoot);
        } else {
            IBuddleBridge _bridge = IBuddleBridge(buddleBridge[_chain]);
            _bridge.transferFunds(_tokens, _amounts);
            _bridge.approveRoot(stateRoot);
        }
    }

    function transferFunds(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) public payable checkInitialization {

        L1StandardBridge _bridge;
        _bridge.initialize(messenger, tokenBridge);

        for(uint i=0; i < _tokens.length; i++) {
            if(_tokens[i] == BASE_TOKEN_ADDRESS) {
                require(msg.value >= _amounts[i], "Insufficient funds sent");
                _bridge.depositETHTo(destContract, 1000000, bytes(""));
            } else {
                IERC20 token = IERC20(_tokens[i]);
                require(token.balanceOf(msg.sender) >= _amounts[i], "Insufficient funds sent");
                token.approve(messenger, _amounts[i]);
                
                _bridge.depositERC20To(
                    tokenMap[_tokens[i]], // L1 token address
                    _tokens[i], // L2 token address
                    destContract, // to address
                    _amounts[i], // amount to be transferred
                    1000000, // Gas limit 
                    bytes("") // Data empty
                );
            }
        }

    }

    function approveRoot(bytes32 _root) public checkInitialization {

        L1CrossDomainMessenger _messenger;
        _messenger.initialize(addressManager);

        _messenger.sendMessage(
            destContract,
            abi.encodeWithSignature(
                "approveStateRoot(uint, bytes32)",
                CHAIN, _root
            ),
            1000000
        );

    }
}