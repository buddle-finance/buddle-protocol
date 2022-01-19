pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@eth-optimism/contracts/L1/messaging/L1CrossDomainMessenger.sol";
import "@eth-optimism/contracts/L1/messaging/L1StandardBridge.sol";
import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

contract BuddleDestOptimism is Ownable {
    address constant ETHER_ADDRESS = address(0);

    address ovmL2CrossDomainMessenger; // Address of deployed L2CrossDomainMessenger contract on Optimism
    address tokenBridge; // The bridge deployed on the Layer-1 chain
    address srcContract; // Address of deployed Source Side contract on Optimism

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
    }

    mapping(uint256 => address payable) transferOwners;
    mapping(uint256 => uint256) transferFee;
    mapping(bytes32 => bool) approvedRoot;


    /// @notice onlyL1Contract modifier
    /// @notice only allows a message from l1DomainSideBridge contract through the L2CrossDomainMessenger bridge
    /// @notice to call the confirmTicketPayed function
    modifier onlyL1Contract() {
        require(
            msg.sender == address(ovmL2CrossDomainMessenger)
            && L2CrossDomainMessenger(ovmL2CrossDomainMessenger).xDomainMessageSender() == tokenBridge
        );
        _;
    }


    bool isInitialized = false;
    function initialize(
        address _ovmL2CrossDomainMessenger,
        address _tokenBridge,
        address _sourceContract
    ) public onlyOwner {
        require(!isInitialized, "Optimism Destination Contract already initialized!");
        
        ovmL2CrossDomainMessenger = _ovmL2CrossDomainMessenger;
        tokenBridge = _tokenBridge;
        srcContract = _sourceContract;
    }

    function changeOwner(
        TransferData memory _data,
        uint256 _transferID,
        address payable _owner
    ) public {
        require( (transferOwners[_transferID] == msg.sender) ||
            (transferOwners[_transferID] == address(0) && _data.destination == msg.sender),
        "You are not authorized to call this function!");
        transferOwners[_transferID] = _owner;
    }

    // function provideLiquidity(
    //     TransferData memory _data,
    //     uint256 _transferID
    // ) public payable {
    //     require(transferOwners[_transferID] == address(0), "Owner already set for this transfer id");
    //     uint256 fee = this.getLPfee(_data, block.timestamp);
    //     if(_data.tokenAddress == ETHER_ADDRESS) {
    //         require(msg.value >= (_data.amount - fee), "Insufficent funds to transfer");
            
    //     } else {

    //     }
    // }



    
    function checkProof(
        TransferData memory _transferData,
        uint256 _transferID,
        bytes32[] memory _rootProof,
        bytes32 _rootHash
    )
    
    
}
