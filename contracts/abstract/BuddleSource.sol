// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interface/IBuddleSource.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 *
 *
 */
abstract contract BuddleSource is IBuddleSource, Ownable {
    using SafeERC20 for IERC20;

    bytes32 public VERSION;
    address constant BASE_TOKEN_ADDRESS = address(0);

    uint256 public CONTRACT_FEE_BASIS_POINTS;
    uint256 public CONTRACT_FEE_RAMP_UP;
    
    uint constant public MERKLE_TREE_DEPTH = 32;
    uint constant public MAX_DEPOSIT_COUNT = 2 ** MERKLE_TREE_DEPTH - 1;
    
    bytes32[MERKLE_TREE_DEPTH] internal zeroes;
    mapping(uint256 => bytes32[MERKLE_TREE_DEPTH]) internal branch;

    address public buddleBridge;
    mapping(uint256 => address) public buddleDestination;

    address[] public tokens;
    mapping(address => bool) public tokenMapping;
    mapping(uint256 => mapping(address => uint256)) internal tokenAmounts;
    mapping(uint256 => mapping(address => uint256)) internal bountyAmounts;

    mapping(uint256 => uint256) public transferCount;
    mapping(uint256 => uint256) public lastConfirmedTransfer;
    mapping(uint256 => mapping(bytes32 => bool)) internal tickets;

    /********** 
     * events *
     **********/

    event TransferStarted(
        TransferData transferData,
        uint256 transferID,
        bytes32 node,
        uint256 srcChain
    );
    
    event TicketCreated(
        bytes32 ticket,
        uint256 destChain,
        address[] tokens,
        uint256[] amounts,
        uint256[] bounty,
        uint256 firstIdForTicket,
        uint256 lastIdForTicket,
        bytes32 stateRoot
    );

    event TicketConfirmed(
        bytes32 ticket,
        bytes32 stateRoot
    );

    /************
     * modifers *
     ************/

    /**
     * Checks whether the contract is initialized
     *
     */
    modifier checkInitialization() {
        require(buddleBridge != address(0), "Contract not yet initialzied");
        _;
    }

    /**
     * Checks whether a destination contract exists for the given chain id
     *
     */
    modifier supportedChain(uint256 _chain) {
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

    /********************** 
     * virtual functions *
     ***********************/
    
    /**
    * Returns true if the msg.sender is the buddleBridge contract address
    *
    */
    function isBridgeContract() internal virtual returns (bool);

    /**
    * Emits the TransferStarted event with the constant CHAIN id in derived contract
    *
    * @param _data The TransferData to be emitted
    * @param _id The Transfer ID to be emitted
    * @param _node The hashed node corresponding to the transfer data and id
    */
    function _emitTransfer(
        TransferData memory _data,
        uint256 _id,
        bytes32 _node
    ) internal virtual;

    /**
    * Bridges the funds as described by _tokenAmounts and _bountyAmounts to the _provider
    * on layer 1.
    * @notice called by confirmTicket(...)
    *
    * @param _destChain The destination chain id for the ticket created
    * @param _tokens The list of ERC20 contract addresses included in ticket
    * @param _tokenAmounts The corresponding list of transfer amounts summed
    * @param _bountyAmounts The corresponding list of bounty fees summed
    * @param _provider The bounty seeker on layer 1
    */
    function _bridgeFunds(
        uint256 _destChain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        uint256[] memory _bountyAmounts,
        address _provider
    ) internal virtual;

    /********************** 
     * onlyOwner functions *
     ***********************/

    /**
     * @inheritdoc IBuddleSource
     */
    function initialize(
        bytes32 _version,
        uint256 _feeBasisPoints,
        uint256 _feeRampUp,
        address _buddleBridge
    ) external onlyOwner {
        require(buddleBridge == address(0), "Contract already initialized!");
        
        VERSION = _version;
        CONTRACT_FEE_BASIS_POINTS = _feeBasisPoints;
        CONTRACT_FEE_RAMP_UP = _feeRampUp;
        buddleBridge = _buddleBridge;

        // Initialize the empty sparse merkle tree
        for (uint height = 0; height < MERKLE_TREE_DEPTH - 1; height++) {
            zeroes[height + 1] = sha256(abi.encodePacked(zeroes[height], zeroes[height]));
        }

        // Add underlying token to supported tokens
        tokens.push(BASE_TOKEN_ADDRESS);
        tokenMapping[BASE_TOKEN_ADDRESS] = true;
    }

    /**
     * @inheritdoc IBuddleSource
     */
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

    /**
     * @inheritdoc IBuddleSource
     */
    function addDestination(
        uint256 _chain,
        address _contract
    ) external onlyOwner checkInitialization {
        require(buddleDestination[_chain] == address(0), 
            "Destination contract already exists for given chain id"
        );
        buddleDestination[_chain] = _contract;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function updateContractFeeBasisPoints(
        uint256 _newContractFeeBasisPoints
    ) external onlyOwner checkInitialization {
        CONTRACT_FEE_BASIS_POINTS = _newContractFeeBasisPoints;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function updateContractFeeRampUp(
        uint256 _newContractFeeRampUp
    ) external onlyOwner checkInitialization {
        CONTRACT_FEE_RAMP_UP = _newContractFeeRampUp;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function updateBuddleBridge(
        address _newBridgeAddress
    ) external onlyOwner checkInitialization {
        buddleBridge = _newBridgeAddress;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function updateDestination(
        uint256 _chain,
        address _contract
    ) external onlyOwner checkInitialization supportedChain(_chain) {
        buddleDestination[_chain] = _contract;
    }

    /********************** 
     * public functions *
     ***********************/

    /**
     * @inheritdoc IBuddleSource
     */
    function deposit(
        address _tokenAddress,
        uint256 _amount,
        address _destination,
        uint256 _destChain
    ) external payable 
      checkInitialization
      supportedChain(_destChain)
      supportedToken(_tokenAddress)
      returns(bytes32) {

        require(transferCount[_destChain] < MAX_DEPOSIT_COUNT,
            "Maximum deposit count reached for given destination chain"
        );

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
        data.chain = _destChain;
        
        if (data.tokenAddress == address(0)) {
            require(msg.value >= amountPlusFee, "Insufficient amount");
        } else {
            IERC20 token = IERC20(data.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amountPlusFee);
        }
        transferCount[_destChain] += 1;
        tokenAmounts[_destChain][_tokenAddress] += data.amount;
        bountyAmounts[_destChain][_tokenAddress] += data.fee;
        
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
            sha256(abi.encodePacked(buddleDestination[_destChain])),
            sha256(abi.encodePacked(transferCount[_destChain]))
        ));
        updateMerkle(_destChain, node);
        
        _emitTransfer(data, transferCount[_destChain], node);

        return node;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function createTicket(uint256 _destChain) external checkInitialization returns(bytes32) {
        uint256[] memory _tokenAmounts = new uint256[](tokens.length);
        uint256[] memory _bountyAmounts = new uint256[](tokens.length);
        bytes32 _ticket;
        for (uint n = 0; n < tokens.length; n++) {
            _tokenAmounts[n] = tokenAmounts[_destChain][tokens[n]];
            _bountyAmounts[n] = bountyAmounts[_destChain][tokens[n]];
            _ticket = sha256(abi.encodePacked(_ticket, tokens[n], _tokenAmounts[n]+_bountyAmounts[n]));
        }
        bytes32 _root = getMerkleRoot(_destChain);
        _ticket = sha256(abi.encodePacked(_ticket, lastConfirmedTransfer[_destChain]));
        _ticket = sha256(abi.encodePacked(_ticket, transferCount[_destChain]));
        _ticket = sha256(abi.encodePacked(_ticket, _root));
        tickets[_destChain][_ticket] = true;

        emit TicketCreated(
            _ticket,
            _destChain,
            tokens,
            _tokenAmounts,
            _bountyAmounts,
            lastConfirmedTransfer[_destChain],
            transferCount[_destChain],
            _root
        );
        
        return _ticket;
    }

    /**
     * @inheritdoc IBuddleSource
     */
    function confirmTicket(
        bytes32 _ticket,
        uint256 _destChain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        uint256[] memory _bountyAmounts,
        uint256 _firstTransferInTicket, 
        uint256 _lastTransferInTicket,
        bytes32 _stateRoot,
        address _provider
    ) external checkInitialization {

        require(isBridgeContract(), "Only the Buddle Bridge contract can call this method");
        
        // Build ticket to check validity of data
        bytes32 ticket;
        for (uint n = 0; n < _tokens.length; n++) {
            ticket = sha256(abi.encodePacked(ticket, _tokens[n], _tokenAmounts[n]+_bountyAmounts[n]));
        }
        ticket = sha256(abi.encodePacked(ticket, _firstTransferInTicket));
        ticket = sha256(abi.encodePacked(ticket, _lastTransferInTicket));
        ticket = sha256(abi.encodePacked(ticket, _stateRoot));
        require(ticket == _ticket, "Invalid ticket formed");
        require(tickets[_destChain][_ticket], "Ticket unknown to contract");

        lastConfirmedTransfer[_destChain] = _lastTransferInTicket;
        tickets[_destChain][_ticket] = false; // Reset to prevent double spend

        _bridgeFunds(_destChain, _tokens, _tokenAmounts, _bountyAmounts, _provider);

        emit TicketConfirmed(_ticket, _stateRoot);
    }

    /********************** 
     * internal functions *
     ***********************/

    /**
     * Update the Merkle Tree representation with the new node
     * @dev Taken from Ethereum's deposit contract
     * @dev see https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code#L1
     */
    function updateMerkle(uint256 _chain, bytes32 _node) internal {
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
    function getMerkleRoot(uint256 _chain) internal view checkInitialization returns (bytes32) {
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