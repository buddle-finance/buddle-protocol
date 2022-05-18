// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interface/IBuddleBridge.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * 
 *
 */
abstract contract BuddleBridge is IBuddleBridge, Ownable {

    address constant BASE_TOKEN_ADDRESS = address(0);

    BuddleContracts public buddle; // deployed Buddle src and dest contracts on respective layer 2

    mapping(address => address) public tokenMap; // l2 token address => l1 token address
    mapping(uint => address) public buddleBridge; // Chain ID => Buddle Bridge Contract Address
    mapping(address => bool) public knownBridges; // Buddle Bridge Contract Address => true


    /** Modifiers */

    /**
     * Checks whether a destination contract exists for the given chain id
     *
     */
    modifier supportedChain(uint _chain) {
        require(buddleBridge[_chain] != address(0), 
            "A bridge contract for the desired chain does not exist yet"
        );
        _;
    }

    /**
     * Checks whether the function is called from a known Buddle bridge contract
     *
     */
    modifier onlyKnownBridge() {
        require(knownBridges[msg.sender], "Unauthorized call from unknown contract");
        _;
    }

    /* onlyOwner functions */

    function setSource(
        address _src
    ) external onlyOwner {
        require(_src != address(0), "Source cannot be the zero address!");
        buddle.source = _src;
    }

    function setDestination(
        address _dest
    ) external onlyOwner {
        require(_dest != address(0), "Destination cannot be the zero address!");
        buddle.destination = _dest;
    }

    function addTokenMap(
        address _l2TokenAddress,
        address _l1TokenAddress 
    ) external onlyOwner {
        require(tokenMap[_l2TokenAddress] == address(0), "A token map already exists.");
        tokenMap[_l2TokenAddress] = _l1TokenAddress;
    }

    function updateTokenMap(
        address _l2TokenAddress,
        address _l1TokenAddress 
    ) external onlyOwner {
        require(tokenMap[_l2TokenAddress] != address(0), "A token map does not exist.");
        tokenMap[_l2TokenAddress] = _l1TokenAddress;
    }

    function addBuddleBridge(
        uint _chain,
        address _contract
    ) external onlyOwner {
        require(buddleBridge[_chain] == address(0),
            "A Buddle Bridge Contract already exists for given chain"
        );
        buddleBridge[_chain] = _contract;
        knownBridges[_contract] = true;
    }

    function updateBuddleBridge(
        uint _chain,
        address _contract
    ) external onlyOwner supportedChain(_chain) {
        knownBridges[buddleBridge[_chain]] = false;
        buddleBridge[_chain] = _contract;
        knownBridges[_contract] = true;
    }
}