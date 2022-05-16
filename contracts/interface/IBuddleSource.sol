//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

interface IBuddleSource {

    struct TransferData {
        address tokenAddress;
        address destination;
        uint256 amount;
        uint256 fee;
        uint256 startTime;
        uint256 feeRampup;
        uint chain;
    }

    /**
     * Initialize the contract with state variables
     * 
     * @param _feeBasisPoints The fee per transfer in basis points
     * @param _feeRampUp The fee ramp up for each transfer
     * @param _messenger The Layer-2 Cross Domain messenger contract for Optimism
     * @param _buddleBridge The Layer-1 Buddle Bridge contract
     * @param _stdBridge The Layer-1 Standard Bridge contract for Optimism
     */
    function initialize(
        uint256 _feeBasisPoints,
        uint256 _feeRampUp,
        address _messenger,
        address _buddleBridge,
        address _stdBridge
    ) external;

    /**
     * Add supported tokens to the contract
     *
     */
    function addTokens(
        address[] memory _tokens
    ) external;

    /**
     * Add the destination contract address for a given chain id
     *
     */
    function addDestination(
        uint _chain,
        address _contract
    ) external;

    /**
     * Change the contract fee basis points
     *
     */
    function changeContractFeeBasisPoints(
        uint256 _newContractFeeBasisPoints
    ) external;

    /**
     * Change the contract fee ramp up
     *
     */
    function changeContractFeeRampUp(
        uint256 _newContractFeeRampUp
    ) external;

    /**
     * Change the buddle bridge address
     *
     */
    function changeBuddleBridge(
        address _newBridgeAddress
    ) external;

    /**
     * Change the layer-2 cross domain messenger
     *
     */
    function changeXDomainMessenger(
        address _newMessengerAddress
    ) external;

    /**
     * Change the Optimsm L1 Standard bridge address
     *
     */
    function changeStandardBridge(
        address _newBridgeAddress
    ) external;

    /**
     * Change the Destination contract address for the given chain id
     *
     */
    function changeDestination(
        uint _chain,
        address _contract
    ) external;

    /**
     * @notice previously `widthdraw`
     * 
     * Deposit funds into the contract to start the bridging process
     * 
     * @param _tokenAddress The contract address of the token being bridged
     *  is address(0) if base token
     * @param _destination The destination address for the bridged tokens
     * @param _amount The amount of tokens to be bridged
     * @param _chain The chain ID for the destination blockchain
     */
    function deposit(
        address _tokenAddress,
        uint256 _amount,
        address _destination,
        uint _chain
    ) external payable returns(bytes32 node);

    /**
     * Create a ticket before providing liquidity to the L1 bridge
     * LP creates this ticket and provides liquidity to win the bounty
     *
     * @param _chain The chain ID for the destination blockchain
     */
    function createTicket(
        uint _chain
    ) external returns(bytes32 node);

    /**
     * Confirms the ticket once liquidity is provided on the Layer-1 Buddle Bridge contract
     * @notice can only be called by the cross domain messenger
     *
     * @param _ticket The ticket to be confirmed
     * @param _chain The chain ID for the destination blockchain
     * @param _tokens The token addresses included in the ticket
     * @param _tokenAmounts The token amounts included in the ticket
     * @param _firstTransferInTicket The initial transfer ID included in ticket
     * @param _lastTransferInTicket The final transfer ID included in ticket
     * @param _stateRoot The state root included in ticket
     * @param _provider The liquidity provider on the L1 bridge contract
     */
    function confirmTicket(
        bytes32 _ticket,
        uint _chain,
        address[] memory _tokens,
        uint256[] memory _tokenAmounts, 
        uint256 _firstTransferInTicket, 
        uint256 _lastTransferInTicket, 
        bytes32 _stateRoot,
        address payable _provider
    ) external;
}