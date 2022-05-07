// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";
import "hardhat/console.sol";


contract BuddleSrcOptimism is Ownable {
    using SafeERC20 for IERC20;

    uint constant public MERKLE_TREE_DEPTH = 32;
    uint constant public MAX_DEPOSIT_COUNT = 2 ** MERKLE_TREE_DEPTH - 1;
    address constant ETHER_ADDRESS = address(0);
    
    bytes32[MERKLE_TREE_DEPTH] private branch;
    bytes32[MERKLE_TREE_DEPTH] private zeroes;

    address ovmL2CrossDomainMessenger;  // ovmL2CrossDomainMessenger contract address(Optimism)
    address l1DomainSideContract;  // l1DomainSideContract deployed contract address on mainnet
    
    uint256 public CONTRACT_FEE_BASIS_POINTS;
    uint256 public feeRampUp;

    uint256 public nextTransferID;
    address[] tokens;
    mapping (address => bool) public tokenMapping;

    mapping(bytes32 => bool) validTicket; // A mapping of valid ticket to prevent reentry
    uint256 public lastPaidByTicketId;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public bountyPool;

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
    }

    // events
    event TransferInitiated(TransferData data, BuddleSrcOptimism self, uint256 nextTransferID);
    event Ticket(bytes32 ticket, address[] tokens, uint256[] amounts, uint256 firstIdForTicket, uint256 lastIdForTicket, bytes32 stateRoot);

    /// @notice onlyL1Contract modifier
    /// @notice only allows a message from l1DomainSideBridge contract through the L2CrossDomainMessenger bridge
    /// @notice to call the confirmTicketPayed function
    modifier onlyL1Contract() {
        require(
            msg.sender == address(ovmL2CrossDomainMessenger)
            && L2CrossDomainMessenger(ovmL2CrossDomainMessenger).xDomainMessageSender() == l1DomainSideContract
        );
        _;
    }

    bool isInitialized = false;
    function initialize(uint256 _feeRampUp, uint256 _freeBasisPoints, address _ovmL2CrossDomainMessenger, address _l1DomainSideContract) public onlyOwner {
        if (isInitialized) {
            revert("Contract already initialized");
        }
        CONTRACT_FEE_BASIS_POINTS = _freeBasisPoints;
        feeRampUp = _feeRampUp;
        ovmL2CrossDomainMessenger = _ovmL2CrossDomainMessenger;
        l1DomainSideContract = _l1DomainSideContract;

        for (uint height = 0; height < MERKLE_TREE_DEPTH - 1; height++) {
            zeroes[height + 1] = sha256(abi.encodePacked(zeroes[height], zeroes[height]));
        }
    }

    function addTokens(address[] memory _tokens) public {
        for(uint i = 0; i < _tokens.length; i++) {
            if (!tokenMapping[_tokens[i]]) {
                revert("Token already added");
            }

            tokens.push(_tokens[i]);
            tokenMapping[_tokens[i]] = true;
        }
    }

    function widthdraw(address _tokenAddress, address _destination, uint256 _amount) public payable returns(bytes32) {

        uint256 amountPlusFee = (_amount * (10000 + CONTRACT_FEE_BASIS_POINTS)) / 10000;

        TransferData memory data;
        data.tokenAddress = _tokenAddress;
        data.destination = _destination;
        data.amount = _amount;
        data.fee = amountPlusFee - data.amount;
        data.startTime = block.timestamp;
        data.feeRampup = feeRampUp;

        if (data.tokenAddress == address(0)) {
            require(msg.value == amountPlusFee, "Insufficient amount");
        } else {
            IERC20 token = IERC20(data.tokenAddress);
            token.safeTransferFrom(msg.sender, address(this), amountPlusFee);
        }
        
        bytes32 transferDataHash = sha256(abi.encodePacked(data.tokenAddress, data.destination, data.amount, data.fee, data.startTime, data.feeRampup));
        bytes32 contractHash = sha256(abi.encodePacked(address(this)));
        bytes32 nextTransferIDHash = sha256(abi.encodePacked(nextTransferID));

        bytes32 node = sha256(abi.encodePacked(transferDataHash, contractHash, nextTransferIDHash));

        nextTransferID += 1;
        updateMerkle(node);
        
        emit TransferInitiated(data, this, nextTransferID);
        
        return node;
    }

    // Copied the logic from Ethereum PoS deposit contract
    function updateMerkle(bytes32 _node) public {
        uint size = nextTransferID % MAX_DEPOSIT_COUNT;
        for (uint depth = 0; depth < MERKLE_TREE_DEPTH; depth++) {

            if ((size & 1) == 1) {
                branch[depth] = _node;
                return;
            }

            _node = sha256(abi.encodePacked(branch[depth], _node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    /// @notice get_deposit_root function
    /// @notice calculates the current merkle tree root
    function get_deposit_root()  external view returns (bytes32) {
        bytes32 node;
        uint size = nextTransferID % MAX_DEPOSIT_COUNT;
        //console.log("size %d", size);
        uint count =0;
        for (uint height = 0; height < MERKLE_TREE_DEPTH; height++) {
            if ((size & 1) == 1)
                node = sha256(abi.encodePacked(branch[height], node));
            else
                node = sha256(abi.encodePacked(node, zeroes[height]));
            size /= 2;
            count += 1;
        }
        return node;
    }

    /// @notice createTicket function
    /// @notice to win the bountry you need first to create a ticket
    /// @notice on the source rollup, which returns a hash of the
    /// @notice current merkle root, first transaction id and last
    /// @notice transaction id that the bounty covers
    /// @notice the bounty seeker needs to deposit all the required
    /// @notice tokens in a contract in the L1 mainnet, then the L1
    /// @notice contract sends the tokens to the destination side rollup
    /// @notice and calls the confirmTicketPayed function in the source
    /// @notice side rollup, which transfers the bounty to the bounty winner
    function createTicket() external returns(bytes32) {
        uint256[] memory tokensAmounts;
        bytes32 ticket;
        for (uint n = 0; n < tokens.length; n++) {
            if(tokens[n] == ETHER_ADDRESS) {
                tokensAmounts[n] = address(this).balance;
            } else {
                IERC20 token = IERC20(tokens[n]);
                tokensAmounts[n] = token.balanceOf(address(this));      
            }
            ticket = sha256(abi.encodePacked(ticket, tokens[0], tokensAmounts[0]));
        }
        bytes32 root = this.get_deposit_root();
        ticket = sha256(abi.encodePacked(ticket, lastPaidByTicketId));
        ticket = sha256(abi.encodePacked(ticket, nextTransferID));
        ticket = sha256(abi.encodePacked(ticket, root));
        validTicket[ticket] = true;
        emit Ticket(ticket, tokens, tokensAmounts, lastPaidByTicketId, nextTransferID, root);
        return ticket;
    }

    /// @notice confirmTicket function
    /// @notice this function is called by the L1 mainnet contract 
    /// @notice it confirms a valid ticket and transfers the bounty to the bounty winner
    function confirmTicket(
        bytes32 _ticket, 
        address[] memory _tokens,
        uint256[] memory _tokensAmounts, 
        uint256 _firstIdForTicket, 
        uint256 _lastIdForTicket, 
        bytes32 stateRoot,
        address payable lp
    ) external onlyL1Contract {

        bytes32 ticket;
        for (uint n = 0; n < _tokens.length; n++) {
            ticket = sha256(abi.encodePacked(ticket,_tokens[0], _tokensAmounts[0]));
        }
        ticket = sha256(abi.encodePacked(ticket,lastPaidByTicketId));
        ticket = sha256(abi.encodePacked(ticket,nextTransferID));
        ticket = sha256(abi.encodePacked(ticket,stateRoot));
        require(_firstIdForTicket == lastPaidByTicketId, "Invalid ticket !!");
        require(ticket == _ticket, "Wrong ticket !!");
        require(validTicket[_ticket] == true, "Invalid ticket !!");
        lastPaidByTicketId = _lastIdForTicket;
        validTicket[_ticket] = false;

        for (uint n = 0; n < _tokens.length; n++) {
            if(tokens[n] == ETHER_ADDRESS) {
                lp.transfer(_tokensAmounts[n]);
            } else {
                IERC20 token = IERC20(_tokens[n]);
                token.transfer(lp, _tokensAmounts[n]);
            }
        }
    }

    function changeContractFeeBasisPoints(uint256 newContractFeeBasisPoints) public onlyOwner {
        CONTRACT_FEE_BASIS_POINTS = newContractFeeBasisPoints;
    }

    function changeContractFeeRampUp(uint256 newContractFeeRampUp) public onlyOwner {
        feeRampUp = newContractFeeRampUp;
    }
}



