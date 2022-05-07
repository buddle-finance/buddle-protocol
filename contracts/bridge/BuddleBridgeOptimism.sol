// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@eth-optimism/contracts/L1/messaging/L1CrossDomainMessenger.sol";
import "@eth-optimism/contracts/L1/messaging/L1StandardBridge.sol";
import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";


contract BuddleBridgeOptimism {
    address constant ETHER_ADDRESS = address(0);

    address srcContract; // Address of deployed Source Side contract on Optimism
    address destContract; // Address of deployed Destination Side contract on Optimism
    address messenger; // Optimism messenger address
    address tokenBridge; // 
    address libraryAddressManager; // Source & Destintion side rollup(Optimism) libAddressManager contract address

    mapping(address => address) tokenToDest; // Mapping of source address to destination address
    address admin; // Address of the admin which can change the tokenToDest mapping

    bool isInitalised = false;

    modifier isAdmin {
        require(msg.sender == admin, "You are not admin!");
        _;
    }

    modifier emptyPair(address _source) {
        require(tokenToDest[_source] == address(0), "Source is already paired!");
        _;
    }

    /// @notice Intialize the contract with variables
    function initialize(
        address _messenger, 
        address _tokenBridge, 
        address _libraryAddressManager,
        address _admin
    ) public {
        require(!isInitalised, "Contract already initialized!");

        messenger = _messenger;
        tokenBridge = _tokenBridge;
        libraryAddressManager = _libraryAddressManager;
        admin = _admin;
        isInitalised = true; 
    }

    /* TODO
     * Remove `require` in favor of checking for empty contract
     * and then changing the address for upgradability
     */
    function setContracts(address _src, address _dest) public isAdmin {
        require(srcContract == address(0) && destContract == address(0), 
            "Contract address can only be set once currently");
        srcContract = _src;
        destContract = _dest;
    }

    function claimBounty(
        bytes32 _ticket,
        address[] memory _tokens,
        uint256[] memory _amounts,
        uint256 _firstIdForTicket,
        uint256 _lastIdForTicket,
        bytes32 stateRoot
    ) external payable {
        L1CrossDomainMessenger ovmL1CrossDomainMessenger;
        ovmL1CrossDomainMessenger.initialize(libraryAddressManager);

        L1StandardBridge l1Bridge;
        l1Bridge.initialize(messenger, tokenBridge);

        ovmL1CrossDomainMessenger.sendMessage(
            srcContract,
            abi.encodeWithSignature(
                "confirmTicket(bytes32,address[],uint256[],uint256,uint256,bytes32,address)",
                _ticket, _tokens, _amounts, _firstIdForTicket, 
                 _lastIdForTicket, stateRoot, msg.sender
            ),
            1000000
        );

        for(uint i=0; i < _tokens.length; i++) {
            if(_tokens[i] == ETHER_ADDRESS) {
                require(msg.value >= _amounts[i], "Insufficient funds sent");
                l1Bridge.depositETHTo(destContract, 1000000, "");
            } else {
                IERC20 token = IERC20(_tokens[i]);
                require(token.balanceOf(msg.sender) >= _amounts[i], "Insufficient funds sent");
                token.approve(messenger, _amounts[i]);
                
                l1Bridge.depositERC20To(
                    _tokens[i], 
                    tokenToDest[_tokens[i]], 
                    destContract, 
                    _amounts[i],
                    1000000, // Gas limit 
                    "" // Data empty
                );
            }
            // replace to sha256 is issue occur
            // TODO: Remove if unused
            _ticket = sha256(abi.encodePacked(_ticket, _tokens[0], _amounts[0]));
        }

        ovmL1CrossDomainMessenger.sendMessage(
            destContract,
            abi.encodeWithSignature(
                "approveSrc(bytes32)",
                stateRoot
            ),
            1000000
        );
    }
    
    function addTokenAddress(address _src, address _dest) public isAdmin emptyPair(_src) {
        tokenToDest[_src] = _dest;
    }
    
}