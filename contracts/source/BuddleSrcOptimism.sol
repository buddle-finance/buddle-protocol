// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interface/IBuddleSource.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@eth-optimism/contracts/L2/messaging/L2StandardBridge.sol";
import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";


contract BuddleSrcOptimism is IBuddleSource, Ownable {
    using SafeERC20 for IERC20;

    uint constant public MERKLE_TREE_DEPTH = 32;
    uint constant public MAX_DEPOSIT_COUNT = 2 ** MERKLE_TREE_DEPTH - 1;
    address constant BASE_TOKEN_ADDRESS = address(0);
    
    uint256 public CONTRACT_FEE_BASIS_POINTS;
    uint256 public CONTRACT_FEE_RAMP_UP;

    address messenger;  // L2 blockchain cross domain messenger contract address
    address stdBridge; // L1 Standard bridge for Optimism

    address buddleBridge;  // L1 blockchain Token Bridge contract address
    mapping(uint => address) public buddleDestination; // ChainID => Destination Contract Address
    
    address[] tokens;
    mapping(address => bool) public tokenMapping;

    mapping(uint => uint256) public transferCount;
    mapping(uint => uint256) public lastConfirmedTransfer;
    mapping(uint => mapping(bytes32 => bool)) private tickets;

    bytes32[MERKLE_TREE_DEPTH] private zeroes; // Empty sparse tree to build root
    mapping(uint => bytes32[MERKLE_TREE_DEPTH]) private branch;
    
    /* events */
    event TransferEvent(
        TransferData data,
        bytes32 node,
        uint256 id
    );
    event TicketEvent(
        bytes32 ticket,
        address[] tokens,
        uint256[] amounts,
        uint256 firstIdForTicket,
        uint256 lastIdForTicket,
        bytes32 stateRoot
    );

    /* modifiers */

    /**
     * Checks whether the message sender is the L2 messenger contract
     * and whether the message originated from the deployed L1 token bridge
     *
     */
    modifier onlyBridgeContract() {
        require( msg.sender == address(messenger) && 
            L2CrossDomainMessenger(messenger).xDomainMessageSender() == buddleBridge,
            "Only the Buddle Token Bridge can call this method"
        );
        _;
    }

    /**
     * Checks whether the contract is initialized
     *
     */
    modifier checkInitialization() {
        require(messenger != address(0), "Contract not yet initialzied");
        _;
    }

    /**
     * Checks whether a destination contract exists for the given chain id
     *
     */
    modifier supportedChain(uint _chain) {
        require(buddleDestination[_chain] != address(0), 
            "A destination contract on the desired chain does not exist yet"
        );
        _;
    }

    /**
     * Checks whether the given token is supported by this contract
     *
     */
    modifier supportedToken(address _token) {
        require(tokenMapping[_token], "This token is not supported yet");
        _;
    }

    /* onlyOwner functions */

    function initialize(
        uint256 _feeBasisPoints,
        uint256 _feeRampUp,
        address _messenger,
        address _buddleBridge,
        address _stdBridge
    ) external onlyOwner {
        require(messenger == address(0), "Contract already initialized!");

        CONTRACT_FEE_BASIS_POINTS = _feeBasisPoints;
        CONTRACT_FEE_RAMP_UP = _feeRampUp;
        messenger = _messenger;
        buddleBridge = _buddleBridge;
        stdBridge = _stdBridge;

        // Initialize the empty sparse merkle tree
        for (uint height = 0; height < MERKLE_TREE_DEPTH - 1; height++) {
            zeroes[height + 1] = sha256(abi.encodePacked(zeroes[height], zeroes[height]));
        }

        // Add underlying token to supported tokens
        tokens.push(BASE_TOKEN_ADDRESS);
        tokenMapping[BASE_TOKEN_ADDRESS] = true;
    }

    function addTokens(
        address[] memory _tokens
    ) external onlyOwner checkInitialization {
        for(uint i = 0; i < _tokens.length; i++) {
            // Add token to contract only if it doesn't already exist
            if (!tokenMapping[_tokens[i]]) {
                tokens.push(_tokens[i]);
                tokenMapping[_tokens[i]] = true;
            }
        }
    }

    function addDestination(
        uint _chain,
        address _contract
    ) external onlyOwner checkInitialization {
        require(buddleDestination[_chain] == address(0), 
            "Destination contract already exists for given chain id"
        );
        buddleDestination[_chain] = _contract;
    }

    function changeContractFeeBasisPoints(
        uint256 _newContractFeeBasisPoints
    ) external onlyOwner checkInitialization {
        CONTRACT_FEE_BASIS_POINTS = _newContractFeeBasisPoints;
    }

    function changeContractFeeRampUp(
        uint256 _newContractFeeRampUp
    ) external onlyOwner checkInitialization {
        CONTRACT_FEE_RAMP_UP = _newContractFeeRampUp;
    }

    function changeBuddleBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        buddleBridge = _newBridgeAddress;
    }

    function changeXDomainMessenger(
        address _newMessengerAddress
    ) external onlyOwner checkInitialization {
        messenger = _newMessengerAddress;
    }

    function changeStandardBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        stdBridge = _newBridgeAddress;
    }

    function changeDestination(
        uint _chain,
        address _contract
    ) external onlyOwner checkInitialization supportedChain(_chain) {
        buddleDestination[_chain] = _contract;
    }

    /* public functions */

    function deposit(
        address _tokenAddress,
        uint256 _amount,
        address _destination,
        uint _chain
    ) external payable 
      checkInitialization
      supportedChain(_chain)
      supportedToken(_tokenAddress)
      returns(bytes32) {

        require(transferCount[_chain] < MAX_DEPOSIT_COUNT,
            "Maximum deposit count reached for given destination"
        );

        // TODO: Change logic to removing fee from amount sent?
        // Calculate fee
        uint256 amountPlusFee = (_amount * (10000 + CONTRACT_FEE_BASIS_POINTS)) / 10000;

        // Build transfer data
        TransferData memory data;
        data.tokenAddress = _tokenAddress;
        data.destination = _destination;
        data.amount = _amount;
        data.fee = amountPlusFee - data.amount;
        data.startTime = block.timestamp;
        data.feeRampup = CONTRACT_FEE_RAMP_UP;
        data.chain = _chain;
        
        // TODO Have a separate private function for this common check
        if (data.tokenAddress == address(0)) {
            require(msg.value >= amountPlusFee, "Insufficient amount");
        } else {
            IERC20 token = IERC20(data.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amountPlusFee);
        }
        
        // Hash Transfer Information and store in tree
        bytes32 transferDataHash = sha256(abi.encodePacked(
            data.tokenAddress,
            data.destination,
            data.amount,
            data.fee,
            data.startTime,
            data.feeRampup,
            data.chain
        ));
        bytes32 node = sha256(abi.encodePacked(
            transferDataHash,
            sha256(abi.encodePacked(buddleDestination[_chain])),
            sha256(abi.encodePacked(transferCount[_chain]))
        ));

        transferCount[_chain] += 1;
        updateMerkle(node, _chain);
        
        // emit TransferEvent(data, this, transferCount); // TODO: remove `this`
        emit TransferEvent(data, node, transferCount[_chain]);
        
        return node;
    }

    function createTicket(uint _chain) external checkInitialization returns(bytes32) {
        uint256[] memory _tokenAmounts;
        bytes32 _ticket;
        for (uint n = 0; n < tokens.length; n++) {
            if(tokens[n] == BASE_TOKEN_ADDRESS) {
                _tokenAmounts[n] = address(this).balance;
            } else {
                IERC20 _token = IERC20(tokens[n]);
                _tokenAmounts[n] = _token.balanceOf(address(this));      
            }
            _ticket = sha256(abi.encodePacked(_ticket, tokens[n], _tokenAmounts[n]));
        }
        bytes32 _root = getMerkleRoot(_chain);
        _ticket = sha256(abi.encodePacked(_ticket, lastConfirmedTransfer[_chain]));
        _ticket = sha256(abi.encodePacked(_ticket, transferCount[_chain]));
        _ticket = sha256(abi.encodePacked(_ticket, _root));
        tickets[_chain][_ticket] = true;

        // Maps to `confirmTicket(bytes32, address[], uint256[], uint256, uint256, bytes32, ...)`
        // _ticket, _tokens, _tokenAmounts, _firstTransferInTicket, _lastTransferInTicket, _stateRoot
        emit TicketEvent(
            _ticket,
            tokens,
            _tokenAmounts,
            lastConfirmedTransfer[_chain],
            transferCount[_chain],
            _root
        );
        
        return _ticket;
    }

    function confirmTicket(
        bytes32 _ticket,
        uint _chain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts, 
        uint256 _firstTransferInTicket, 
        uint256 _lastTransferInTicket, 
        bytes32 _stateRoot,
        address payable _provider
    ) external checkInitialization onlyBridgeContract {
        
        // Build ticket to check validity of data
        bytes32 ticket;
        for (uint n = 0; n < _tokens.length; n++) {
            ticket = sha256(abi.encodePacked(ticket, _tokens[n], _tokenAmounts[n]));
        }
        ticket = sha256(abi.encodePacked(ticket, _firstTransferInTicket));
        ticket = sha256(abi.encodePacked(ticket, _lastTransferInTicket));
        ticket = sha256(abi.encodePacked(ticket, _stateRoot));
        require(ticket == _ticket, "Invalid ticket sent");
        require(tickets[_chain][_ticket], "Ticket unknown to contract");

        lastConfirmedTransfer[_chain] = _lastTransferInTicket;
        tickets[_chain][_ticket] = false; // Reset to prevent double spend

        // Send funds mentioned in ticket to token bridge liquidity provider
        // TODO: Send funds to L2 standard bridge

        for (uint n = 0; n < _tokens.length; n++) {
            if(tokens[n] == BASE_TOKEN_ADDRESS) {
                _provider.transfer(_tokenAmounts[n]);
            } else {
                IERC20 token = IERC20(_tokens[n]);
                token.safeTransfer(_provider, _tokenAmounts[n]);
            }
        }
    }

    /* internal functions */

    /**
     * Update the Merkle Tree representation with the new node
     * @dev Taken from Ethereum's deposit contract
     * @dev see https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code#L1
     */
    function updateMerkle(bytes32 _node, uint _chain) internal {
        uint size = transferCount[_chain] % MAX_DEPOSIT_COUNT;
        for (uint height = 0; height < MERKLE_TREE_DEPTH; height++) {

            // Check odd, ie, left neighbour
            if ((size & 1) == 1) {
                branch[_chain][height] = _node;
                return;
            }

            _node = sha256(abi.encodePacked(branch[_chain][height], _node));
            size /= 2;
        }
        
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    /**
     * Get the current merkle root stored in the contract
     * @dev Taken from Ethereum's deposit contract
     * @dev see https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code#L1
     *
     */
    function getMerkleRoot(uint _chain) internal view checkInitialization returns (bytes32) {
        bytes32 node;
        uint size = transferCount[_chain] % MAX_DEPOSIT_COUNT;
        for (uint height = 0; height < MERKLE_TREE_DEPTH; height++) {
            if ((size & 1) == 1)
                node = sha256(abi.encodePacked(branch[_chain][height], node));
            else
                node = sha256(abi.encodePacked(node, zeroes[height]));
            size /= 2;
        }
        return node;
    }

}