// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRouterClient} from "cross-not-official/contracts/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "cross-not-official/contracts/OwnerIsCreator.sol";
import {Client} from "cross-not-official/contracts/libraries/Client.sol";
import {CCIPReceiver} from "cross-not-official/contracts/applications/CCIPReceiver.sol";
import {IERC20} from "cross-not-official/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";

interface IMasterVoter
{
    struct VoteData {
        address voter;
        uint256 postID;
        uint256 eventId;
        uint256 amount;
        uint256 timestamp;
    }
    function masterUpvote(VoteData memory voteData) external;
}

/// @title - A simple messenger contract for sending/receiving string messages across chains.
/// Pay using native tokens (e.g, ETH in Ethereum)
contract VoterCC is CCIPReceiver, OwnerIsCreator {
    // Custom errors to provide more descriptive revert messages.
    error NoMessageReceived(); // Used when trying to access a message but no messages have been received.
    error IndexOutOfBound(uint256 providedIndex, uint256 maxIndex); // Used when the provided index is out of bounds.
    error MessageIdNotExist(bytes32 messageId); // Used when the provided message ID does not exist.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error FailedToWithdrawEth(address owner, address target, uint256 value); // Used when the withdrawal of Ether fails.
    mapping(address => bool) public VoterContracts; // X vote equal to 
    mapping(address => bool) public allowlistedSenders; // X vote equal to 

    IMasterVoter masterVoter;
    uint64 public destinationChainSelector;
    address public receiver;
    error SenderNotAllowed(address sender);

    modifier onlyVoterContract() {
        require(VoterContracts[msg.sender], "Not a voter");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    modifier onlyAllowlisted(address _sender) {
        if (!allowlistedSenders[_sender]) revert SenderNotAllowed(_sender);
        _;
    }

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address receiver, // The address of the receiver on the destination chain.
        IMasterVoter.VoteData message, // The message being sent.
        uint256 fees // The fees paid for sending the message.
    );

    // Event emitted when a message is received from another chain.
    event MessageReceived(
        bytes32 indexed messageId, // The unique ID of the message.
        uint64 indexed sourceChainSelector, // The chain selector of the source chain.
        address sender, // The address of the sender from the source chain.
        IMasterVoter.VoteData message // The message that was received.
    );

    // Struct to hold details of a message.
    struct Message {
        uint64 sourceChainSelector; // The chain selector of the source chain.
        address sender; // The address of the sender.
        IMasterVoter.VoteData message; // The content of the message.
    }

    // Storage variables.
    bytes32[] public receivedMessages; // Array to keep track of the IDs of received messages.
    mapping(bytes32 => Message) public messageDetail; // Mapping from message ID to Message struct, storing details of each received message.
    address public _router;

    /// @notice Constructor initializes the contract with the router address.
    /// @param router The address of the router contract.
    constructor(address router) CCIPReceiver(router) {
        _router = router;
    }

    

    function updateRouter(address routerAddr) external onlyOwner {
        _router = routerAddr;
    }

    function updateVoterContracts(address newMasterVoter, bool allowed) external onlyOwner {
        VoterContracts[newMasterVoter] = allowed;
    }

    function updateDestinationChain(uint64 _newChain) external onlyOwner {
        destinationChainSelector = _newChain;
    }

    function updateRecieverCCIP(address _newReceiver) external onlyOwner {
        receiver = _newReceiver;
    }

    function updateMasterVoter(address newMasterVoter) external onlyOwner {
        masterVoter = IMasterVoter(newMasterVoter);
    }

    function getMasterUpvoteFee(uint64 destinationChainSelector, address receiver, IMasterVoter.VoteData memory message) external view returns(uint256) {
        return IRouterClient(_router).getFee(destinationChainSelector, Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encode(message), // ABI-encoded string message
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 400_000, strict: false}) // Additional arguments, setting gas limit and non-strict sequency mode
            ),
            feeToken: address(0) // Setting feeToken to zero address, indicating native asset will be used for fees
        }));
    }

    /// @notice Sends data to receiver on the destination chain.
    /// @dev Assumes your contract has sufficient native asset (e.g, ETH on Ethereum, MATIC on Polygon...).
    /// @param message The string message to be sent.
    /// @return messageId The ID of the message that was sent.
    function sendMessage(
        IMasterVoter.VoteData memory message
    ) public payable onlyVoterContract returns (bytes32 messageId) {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encode(message), // ABI-encoded string message
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 400_000, strict: false}) // Additional arguments, setting gas limit and non-strict sequency mode
            ),
            feeToken: address(0) // Setting feeToken to zero address, indicating native asset will be used for fees
        });

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(_router);

        // Get the fee required to send the message
        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);

        // Send the message through the router and store the returned message ID
        messageId = router.ccipSend{value: fees}(
            destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit MessageSent(
            messageId,
            destinationChainSelector,
            receiver,
            message,
            fees
        );

        // Return the message ID
        return messageId;
    }

    /// handle a received message
    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override onlyAllowlisted(abi.decode(any2EvmMessage.sender, (address))){
        bytes32 messageId = any2EvmMessage.messageId; // fetch the messageId
        uint64 sourceChainSelector = any2EvmMessage.sourceChainSelector; // fetch the source chain identifier (aka selector)
        address sender = abi.decode(any2EvmMessage.sender, (address)); // abi-decoding of the sender address
        IMasterVoter.VoteData memory message = abi.decode(any2EvmMessage.data, (IMasterVoter.VoteData)); // abi-decoding of the sent string message
        receivedMessages.push(messageId);
        Message memory detail = Message(sourceChainSelector, sender, message);
        messageDetail[messageId] = detail;
        //Handle master voter here:
        masterVoter.masterUpvote(message);
        emit MessageReceived(messageId, sourceChainSelector, sender, message);
    }

    /// @notice Get the total number of received messages.
    /// @return number The total number of received messages.
    function getNumberOfReceivedMessages()
        external
        view
        returns (uint256 number)
    {
        return receivedMessages.length;
    }

    /// @notice Fetches the details of the last received message.
    /// @dev Reverts if no messages have been received yet.
    /// @return messageId The ID of the last received message.
    /// @return sourceChainSelector The source chain identifier (aka selector) of the last received message.
    /// @return sender The address of the sender of the last received message.
    /// @return message The last received message.
    function getLastReceivedMessageDetails()
        external
        view
        returns (
            bytes32 messageId,
            uint64 sourceChainSelector,
            address sender,
            IMasterVoter.VoteData memory message
        )
    {
        // Revert if no messages have been received
        if (receivedMessages.length == 0) revert NoMessageReceived();

        // Fetch the last received message ID
        messageId = receivedMessages[receivedMessages.length - 1];

        // Fetch the details of the last received message
        Message memory detail = messageDetail[messageId];

        return (
            messageId,
            detail.sourceChainSelector,
            detail.sender,
            detail.message
        );
    }
    /// @notice Fallback function to allow the contract to receive Ether.
    /// @dev This function has no function body, making it a default function for receiving Ether.
    /// It is automatically called when Ether is sent to the contract without any data.
    receive() external payable {}

    /// @notice Allows the contract owner to withdraw the entire balance of Ether from the contract.
    /// @dev This function reverts if there are no funds to withdraw or if the transfer fails.
    /// It should only be callable by the owner of the contract.
    /// @param beneficiary The address to which the Ether should be sent.
    function withdraw(address beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = address(this).balance;

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        // Attempt to send the funds, capturing the success status and discarding any return data
        (bool sent, ) = beneficiary.call{value: amount}("");

        // Revert if the send failed, with information about the attempted transfer
        if (!sent) revert FailedToWithdrawEth(msg.sender, beneficiary, amount);
    }
}