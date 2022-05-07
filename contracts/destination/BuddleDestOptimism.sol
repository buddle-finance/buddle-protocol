// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@eth-optimism/contracts/L1/messaging/L1CrossDomainMessenger.sol";
import "@eth-optimism/contracts/L1/messaging/L1StandardBridge.sol";
import "@eth-optimism/contracts/L2/messaging/L2CrossDomainMessenger.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BuddleDestOptimism is Ownable {
    using SafeERC20 for IERC20;

    address constant BASE_TOKEN_ADDRESS = address(0);

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
    
    /// @notice buy function
    /// @notice if the owner is zero, anyone can call this function paying the required tokens
    /// @notice and claiming ownership
    function buy(TransferData memory transferData, uint256 transferID) public payable {
        require(transferOwners[transferID] == address(0), "Owner is non zero");
        uint256 fee = getLPFee(transferData, block.timestamp);
        if (transferData.tokenAddress == BASE_TOKEN_ADDRESS) {
            require(msg.value >= (transferData.amount - fee), "Not enough tokens sent");
        } else {
            IERC20 token = IERC20(transferData.tokenAddress);            
            require(token.balanceOf(msg.sender) >= (transferData.amount - fee), "Insufficient token balance");
            require(token.allowance(msg.sender, address(this)) >= (transferData.amount - fee), "Insufficient token allowance");
            token.safeTransferFrom(msg.sender, address(this), (transferData.amount - fee));
        }
        transferFee[transferID] = fee;
        // XXX: Added
        transferOwners[transferID] = payable(msg.sender);
    }

    /// @notice withdraw function
    /// @notice if the contract has enough balance, the owner(or the destination if the owner is zero)
    /// @notice can call this function, the function will confirm the transfer with the state root
    /// @notice and if the transfer is confirmed, the transfer value will be transfered to the 
    /// @notice destination address
    /// @param stateRootProof should be calculated offline
    function withdraw(TransferData memory transferData, uint256 transferID, 
        bytes32[] memory stateRootProof, bytes32 stateRoot) public {

        require((transferOwners[transferID] == address(0) 
                && transferData.destination == msg.sender) ||
                transferOwners[transferID] == msg.sender, 
                "Can only be called by owner or destination if there is no owner.");

        require(checkProof(transferData, transferID, stateRootProof, stateRoot), "Wrong state root or proof.");
        transferOwners[transferID].transfer(transferFee[transferID]);
        if(transferData.tokenAddress == BASE_TOKEN_ADDRESS) {
            require(transferData.amount <= address(this).balance,
             "Contract doesn't have enough funds yet.");

        } else {
            IERC20 token = IERC20(transferData.tokenAddress);
            require(transferData.amount <= token.balanceOf(address(this)),
             "Contract doesn't have enough funds yet.");
            token.transferFrom(address(this), transferData.destination, transferData.amount);
        }       
    }

    
    function checkProof(
        TransferData memory _transferData, 
        uint256 transferID, 
        bytes32[] memory stateRootProof, 
        bytes32 stateRoot
    ) private view returns (bool) {

        bytes32 transferDataHash = sha256(
            abi.encodePacked(
                _transferData.tokenAddress,_transferData.destination,
                _transferData.amount ,_transferData.fee,
                _transferData.startTime,_transferData.feeRampup
            )
        );
        bytes32 contractAddressHash = sha256(abi.encodePacked(srcContract));
        bytes32 nexTransferIdHash = sha256(abi.encodePacked(transferID));
        bytes32 node = sha256(abi.encodePacked(transferDataHash, contractAddressHash,nexTransferIdHash));

        bytes32 value = node;
        for(uint n = 0; n < stateRootProof.length; n++) {
            if(((n / (2**n)) % 2) == 1)
                value = sha256(abi.encodePacked(stateRootProof[n], value));
            else
                value = sha256(abi.encodePacked(value, stateRootProof[n]));
        }
        return (value == stateRoot);
    }

    /// @notice getLPFee function
    /// @notice calculates the liquidity provider fee.
    function getLPFee(TransferData memory _transferData, uint256 _currentTime) private pure returns (uint256) {
        if(_currentTime < _transferData.startTime)
            return 0;
        else if(_currentTime >= _transferData.startTime + _transferData.feeRampup)
            return _transferData.fee;
        else
            return _transferData.fee * (_currentTime - _transferData.startTime); // feeRampup
    }

    /// @notice approveStateRoot function
    /// @notice receives the approved state root message from l1DomainSideBridge contract through the L2CrossDomainMessenger bridge
    function approveStateRoot(bytes32 stateRoot) external onlyL1Contract{
        approvedRoot[stateRoot] = true;
    }
}
