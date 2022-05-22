// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../_abstract/BuddleBridge.sol";

import "@matterlabs/zksync-contracts/contracts/interfaces/IZkSync.sol";
import "@matterlabs/zksync-contracts/contracts/libraries/Operations.sol";

/**
 *
 *
 */
contract BuddleBridgeZkSync is BuddleBridge {
    using SafeERC20 for IERC20;

    uint256 constant public CHAIN = 280; // zkSync alpha testnet

    address public zkSyncAddress;

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
        address _zkSyncAddress
    ) external onlyOwner {
        require(_zkSyncAddress == address(0), "Contract already initialized!");

        VERSION = _version;
        zkSyncAddress = _zkSyncAddress;

        buddleBridge[CHAIN] = address(this);
        knownBridges[address(this)] = true;
    }

    function updateZkSyncAddress(
        address _newZkSyncAddress
    ) external onlyOwner checkInitialization {
        zkSyncAddress = _newZkSyncAddress;
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

        IZkSync zksync = IZkSync(zkSyncAddress);
        // TODO: msg.value returns 0 on zk. Check this and fix
        // uint256 baseCost = zksync.executeBaseCost(...);

        zksync.requestExecute{value: msg.value}(
            buddle.source,
            abi.encodeWithSignature(
                "confirmTicket(bytes32,uint256,address[],uint256[],uint256[],uint256,uint256,bytes32,address)",
                _ticket, _chain, _tokens, _amounts, _bounty, _firstIdForTicket, _lastIdForTicket, stateRoot, msg.sender
            ),
            1000000,
            Operations.QueueType.Deque,
            Operations.OpTree.Full
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

        IZkSync zksync = IZkSync(zkSyncAddress);

        for(uint i=0; i < _tokens.length; i++) {
            if(_tokens[i] == BASE_TOKEN_ADDRESS) {
                require(msg.value >= _amounts[i], "Insufficient funds sent");
                zksync.depositETH{value: msg.value}(
                    msg.value,
                    buddle.destination, 
                    Operations.QueueType.Deque, 
                    Operations.OpTree.Full
                );
            } else {
                IERC20 token = IERC20(_tokens[i]);
                require(token.balanceOf(bountySeeker) >= _amounts[i], "Insufficient funds sent");
                
                token.safeTransferFrom(bountySeeker, address(this), _amounts[i]);
                token.approve(messenger, _amounts[i]);
                
                zksync.depositERC20(
                    tokenMap[_tokens[i]], // L1 token address
                    _amounts[i], // amount to be transferred
                    buddle.destination, // to address
                    Operations.QueueType.Deque,
                    Operations.OpTree.Full // Data empty
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
      payable
      checkInitialization
      onlyKnownBridge {

        IZkSync zksync = IZkSync(zkSyncAddress);

        zksync.requestExecute{value: msg.value}(
            buddle.destination,
            abi.encodeWithSignature(
                "approveStateRoot(uint256,bytes32)",
                CHAIN, _root
            ),
            1000000,
            Operations.QueueType.Deque,
            Operations.OpTree.Full
        );

    }
}