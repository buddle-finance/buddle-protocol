// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";


contract BuddleSrcOptimism is Ownable {
    using SafeERC20 for IERC20;

    uint constant public MERKLE_TREE_DEPTH = 32;
    uint constant public MAX_DEPOSIT_COUNT = 2 ** MERKLE_TREE_DEPTH - 1;
    address constant ETHER_ADDRESS = address(0);
    
    bytes32[MERKLE_TREE_DEPTH] private branch; // Stores the left neighbour at each height of tree
    bytes32[MERKLE_TREE_DEPTH] private zeroes; // Empty sparse tree to build root

    address messenger;  // L2 blockchain cross domain messenger contract address
    address tokenBridge;  // L1 blockchain Token Bridge contract address
    
    uint256 public CONTRACT_FEE_BASIS_POINTS;
    uint256 public CONTRACT_FEE_RAMP_UP;

    uint256 public transferCount;
    address[] tokens;
    mapping (address => bool) public tokenMapping;

    mapping(bytes32 => bool) tickets; // A mapping of valid tickets to prevent reentry
    uint256 public lastConfirmedTransfer; // Stores the last confirmed transfer id

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
    }
    
    /* events */
    event TransferEvent(TransferData data, BuddleSrcOptimism self, uint256 transferCount);
    event TicketEvent(bytes32 ticket, address[] tokens, uint256[] amounts, uint256 firstIdForTicket, uint256 lastIdForTicket, bytes32 stateRoot);

    /* modifiers */

    /*
     *
     *
     */
    modifier onlyBridgeContract() {
        require( msg.sender == address(messenger) && 
            L2CrossDomainMessenger(messenger).xDomainMessageSender() == tokenBridge,
            "Only the Buddle Token Bridge can call this method"
        );
        _;
    }

    /*
     *
     *
     */
    modifier checkInitialization() {
        require(messenger != address(0), "Contract not yet initialzied");
        _;
    }


    /* external functions */

    /* 
     * 
     * @notice previously `widthdraw`
     */
    function deposit(
        address _tokenAddress,
        address _destination,
        uint256 _amount
    ) public payable checkInitialization returns(bytes32) {

        // XXX Change logic to removing fee from amount sent?
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
        
        // TODO Have a separate private function for this common check
        if (data.tokenAddress == address(0)) {
            require(msg.value >= amountPlusFee, "Insufficient amount");
        } else {
            IERC20 token = IERC20(data.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amountPlusFee);
        }
        
        // Hash Transfer Information and store in tree
        bytes32 transferDataHash = sha256(abi.encodePacked(data.tokenAddress, data.destination, data.amount, data.fee, data.startTime, data.feeRampup));
        bytes32 contractHash = sha256(abi.encodePacked(address(this)));
        bytes32 transferCountHash = sha256(abi.encodePacked(transferCount));
        bytes32 node = sha256(abi.encodePacked(transferDataHash, contractHash, transferCountHash));

        transferCount += 1;
        updateMerkle(node);
        
        emit TransferEvent(data, this, transferCount);
        
        return node;
    }

    /*
     * Get the current merkle root from the contract
     *
     */
    function getMerkleRoot() external view checkInitialization returns (bytes32) {
        bytes32 node;
        uint size = transferCount % MAX_DEPOSIT_COUNT;
        for (uint height = 0; height < MERKLE_TREE_DEPTH; height++) {
            if ((size & 1) == 1)
                node = sha256(abi.encodePacked(branch[height], node));
            else
                node = sha256(abi.encodePacked(node, zeroes[height]));
            size /= 2;
        }
        return node;
    }

    /*
     *
     *
     */
    function createTicket() external checkInitialization returns(bytes32) {
        uint256[] memory _tokenAmounts;
        bytes32 _ticket;
        for (uint n = 0; n < tokens.length; n++) {
            if(tokens[n] == ETHER_ADDRESS) {
                _tokenAmounts[n] = address(this).balance;
            } else {
                IERC20 _token = IERC20(tokens[n]);
                _tokenAmounts[n] = _token.balanceOf(address(this));      
            }
            _ticket = sha256(abi.encodePacked(_ticket, tokens[n], _tokenAmounts[n]));
        }
        bytes32 _root = this.getMerkleRoot();
        _ticket = sha256(abi.encodePacked(_ticket, lastConfirmedTransfer));
        _ticket = sha256(abi.encodePacked(_ticket, transferCount));
        _ticket = sha256(abi.encodePacked(_ticket, _root));
        tickets[_ticket] = true;

        // Maps to inputs to `confirmTicket(bytes32, address[], uint256[], uint256, uint256, bytes32, ...)`
        // _ticket, _tokens, _tokenAmounts, _firstTransferInTicket, _lastTransferInTicket, _stateRoot
        emit TicketEvent(_ticket, tokens, _tokenAmounts, lastConfirmedTransfer, transferCount, _root);
        
        return _ticket;
    }

    /*
     *
     *
     */
    function confirmTicket(
        bytes32 _ticket, 
        address[] memory _tokens,
        uint256[] memory _tokenAmounts, 
        uint256 _firstTransferInTicket, 
        uint256 _lastTransferInTicket, 
        bytes32 _stateRoot,
        address payable _provider
    ) external checkInitialization onlyBridgeContract {
        require(tickets[_ticket], "Given ticket is unknown to contract");
        require(lastConfirmedTransfer == _firstTransferInTicket, 
            "Invalid first transfer id included. Perhaps previous tickets have not closed?"
        );

        // Build ticket
        // TODO remove block?
        bytes32 ticket;
        for (uint n = 0; n < _tokens.length; n++) {
            ticket = sha256(abi.encodePacked(ticket, _tokens[n], _tokenAmounts[n]));
        }
        ticket = sha256(abi.encodePacked(ticket, lastConfirmedTransfer));
        ticket = sha256(abi.encodePacked(ticket, _lastTransferInTicket));
        ticket = sha256(abi.encodePacked(ticket, _stateRoot));
        require(ticket == _ticket, "Wrong ticket !!");

        lastConfirmedTransfer = _lastTransferInTicket;
        tickets[_ticket] = false; // Reset to allow for reuse

        // Send funds mentioned in ticket to token bridge liquidity provider
        for (uint n = 0; n < _tokens.length; n++) {
            if(tokens[n] == ETHER_ADDRESS) {
                _provider.transfer(_tokenAmounts[n]);
            } else {
                IERC20 token = IERC20(_tokens[n]);
                token.safeTransfer(_provider, _tokenAmounts[n]);
            }
        }
    }



    /* only owner functions */

    /*
     *
     *
     */
    function initialize(
        uint256 _feeBasisPoints,
        uint256 _feeRampUp,
        address _messenger,
        address _tokenBridge
    ) public onlyOwner {
        require(messenger == address(0), "Contract already initialized!");

        CONTRACT_FEE_BASIS_POINTS = _feeBasisPoints;
        CONTRACT_FEE_RAMP_UP = _feeRampUp;
        messenger = _messenger;
        tokenBridge = _tokenBridge;

        // Initialize the empty sparse merkle tree
        for (uint height = 0; height < MERKLE_TREE_DEPTH - 1; height++) {
            zeroes[height + 1] = sha256(abi.encodePacked(zeroes[height], zeroes[height]));
        }

        // Add underlying token to supported tokens
        tokens.push(ETHER_ADDRESS);
        tokenMapping[ETHER_ADDRESS] = true;
    }

    /*
     *
     *
     */
    function changeContractFeeBasisPoints(
        uint256 _newContractFeeBasisPoints
    ) public onlyOwner checkInitialization {
        CONTRACT_FEE_BASIS_POINTS = _newContractFeeBasisPoints;
    }

    /*
     *
     *
     */
    function changeContractFeeRampUp(
        uint256 _newContractFeeRampUp
    ) public onlyOwner checkInitialization {
        CONTRACT_FEE_RAMP_UP = _newContractFeeRampUp;
    }

    /*
     *
     *
     */
    function changeTokenBridge(
        address _newBridgeAddress
    ) public onlyOwner checkInitialization {
        tokenBridge = _newBridgeAddress;
    }

    /*
     *
     *
     */
    function changeXDomainMessenger(
        address _newMessengerAddress
    ) public onlyOwner checkInitialization {
        messenger = _newMessengerAddress;
    }

    /*
     *
     *
     */
    function addTokens(
        address[] memory _tokens
    ) public onlyOwner checkInitialization {
        for(uint i = 0; i < _tokens.length; i++) {
            // Add token to contract only if it doesn't already exist
            if (!tokenMapping[_tokens[i]]) {
                tokens.push(_tokens[i]);
                tokenMapping[_tokens[i]] = true;
            }
        }
    }

    
    /* private functions */

    /*
     *
     *
     */
    // Copied the logic from Ethereum PoS deposit contract
    function updateMerkle(bytes32 _node) private {
        uint size = transferCount % MAX_DEPOSIT_COUNT;
        for (uint height = 0; height < MERKLE_TREE_DEPTH; height++) {

            // Check odd, ie, left neighbour
            if ((size & 1) == 1) {
                branch[height] = _node;
                return;
            }

            _node = sha256(abi.encodePacked(branch[height], _node));
            size /= 2;
        }
        
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

}



