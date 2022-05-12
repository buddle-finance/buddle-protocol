// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@eth-optimism/contracts/L1/messaging/L1StandardBridge.sol";
import "@eth-optimism/contracts/L1/messaging/L1CrossDomainMessenger.sol";


contract BuddleBridgeOptimism {
    using SafeERC20 for IERC20;

    address constant BASE_TOKEN_ADDRESS = address(0);

    address messenger; // Optimism L1 cross domain messenger address
    address tokenBridge; // Optimism L2 standard bridge
    address addressManager; // Optimism address manager

    address srcContract; // Address of deployed Source Side contract on Optimism
    address destContract; // Address of deployed Destination Side contract on Optimism
    address admin; // Address of the admin which can change the tokenToDest mapping
    mapping(address => address) tokenToDest; // Mapping of source address to destination address

    modifier isAdmin {
        require(msg.sender == admin, "You are not admin!");
        _;
    }

    modifier emptyPair(address _source) {
        require(tokenToDest[_source] == address(0), "Source is already paired!");
        _;
    }

    modifier isInitialized() {
        require(srcContract != address(0), "Contract not initialized yet.");
        _;
    }

    function initialize(
        address _messenger, 
        address _tokenBridge, 
        address _addressManager,
        address _admin
    ) public {
        require(srcContract == address(0), "Contract already initialized!");

        messenger = _messenger;
        tokenBridge = _tokenBridge;
        addressManager = _addressManager;
        admin = _admin;
    }

    /* TODO
     * Remove `require` in favor of checking for empty contract
     * and then changing the address for upgradability
     */
    function setContracts(
        address _src,
        address _dest
    ) external isAdmin isInitialized {
        srcContract = _src;
        destContract = _dest;
    }

    function addTokenAddress(
        address _src, 
        address _dest
    ) external isAdmin emptyPair(_src) isInitialized {
        tokenToDest[_src] = _dest;
    }

    function claimBounty(
        bytes32 _ticket,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _firstIdForTicket,
        uint256 _lastIdForTicket,
        bytes32 stateRoot
    ) external payable {
        L1CrossDomainMessenger _messenger;
        _messenger.initialize(addressManager);

        L1StandardBridge _bridge;
        _bridge.initialize(messenger, tokenBridge);

        _messenger.sendMessage(
            srcContract,
            abi.encodeWithSignature(
                "confirmTicket(bytes32,address[],uint256[],uint256,uint256,bytes32,address)",
                _ticket, _tokens, _amounts, _firstIdForTicket, 
                 _lastIdForTicket, stateRoot, msg.sender
            ),
            1000000
        );

        for(uint i=0; i < _tokens.length; i++) {
            if(_tokens[i] == BASE_TOKEN_ADDRESS) {
                require(msg.value >= _amounts[i], "Insufficient funds sent");
                _bridge.depositETHTo(destContract, 1000000, bytes(""));
            } else {
                IERC20 token = IERC20(_tokens[i]);
                require(token.balanceOf(msg.sender) >= _amounts[i], "Insufficient funds sent");
                token.approve(messenger, _amounts[i]);
                
                _bridge.depositERC20To(
                    _tokens[i], 
                    tokenToDest[_tokens[i]], 
                    destContract, 
                    _amounts[i],
                    1000000, // Gas limit 
                    bytes("") // Data empty
                );
            }
        }

        _messenger.sendMessage(
            destContract,
            abi.encodeWithSignature(
                "approveSrc(bytes32)",
                stateRoot
            ),
            1000000
        );
    }
    
}