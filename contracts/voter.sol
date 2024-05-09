// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IVoteStorage
{
    function upvote(uint256 postID,uint256 eventId,uint256 amount, address sender) external;
}
interface CrossChainContract
{   
    struct VoteData {
        address voter;
        uint256 postID;
        uint256 eventId;
        uint256 amount;
        uint256 timestamp;
    }

    function sendMessage(
        VoteData memory message
    ) external payable returns (bytes32 messageId);

}
contract Voter is Ownable {
    mapping(uint => uint256) public quantityToVotePrice; // X vote equal to 
    uint256 public defaultVotePrice = 1000000;
    uint64 public masterChainID = 12532609583862916517;
    bool public isMasterVoter = false;
    IVoteStorage public voteStorage;
    CrossChainContract public CCIP;
    IERC20 public USDC;
    modifier onlyCCIPAddresses() {
        require(msg.sender == address(CCIP), "Not  not ccip contract");
        _;
    }

    event PaymentTokenUpdated(uint quantity, uint256 basePrice);

    constructor(address _tokenAddress, address _ccip, bool _isMasterVoter) Ownable(msg.sender) {
        USDC = IERC20(_tokenAddress);

        quantityToVotePrice[10] =  8990000;
        quantityToVotePrice[20] =  16990000;
        quantityToVotePrice[50] =  39990000;
        quantityToVotePrice[100] = 78990000;
        quantityToVotePrice[500] =  389990000;
        quantityToVotePrice[1000] = 779990000;
        isMasterVoter = _isMasterVoter;
        CCIP = CrossChainContract(_ccip);
    }

    function ChangeVoteStorage(address _voteStorage) external onlyOwner {
        voteStorage = IVoteStorage(_voteStorage);
    }

    function ChangeCrossChainContract(address _CCIP) external onlyOwner {
        CCIP = CrossChainContract(_CCIP);
    }

    function modifyPricePackage(
        uint _quantity,
        uint256 _votePrice
    ) external onlyOwner {
        if(_quantity == 0) defaultVotePrice = _votePrice;
        quantityToVotePrice[_quantity] = _votePrice;
        emit PaymentTokenUpdated(_quantity, _votePrice);
    }

    function masterUpvote(
        CrossChainContract.VoteData memory voteData
    ) public onlyCCIPAddresses {
        if(isMasterVoter)
        {
            voteStorage.upvote(voteData.postID, voteData.eventId, voteData.amount, voteData.voter);
        }
    }

    function upvote(
        uint256 postID,
        uint256 eventId,
        uint256 amount
    ) public payable {
        require(amount > 0, "Amount must be greater than zero");

        uint256 votePrice = quantityToVotePrice[amount];
        if(votePrice == 0) votePrice = defaultVotePrice;
        uint256 voteValue = votePrice * amount;
        //USDC.transferFrom(msg.sender, address(this), voteValue);
        

        if(!isMasterVoter)
        {
            CrossChainContract.VoteData memory voteData = CrossChainContract.VoteData(
            msg.sender,
            postID,
            eventId,
            amount,
            block.timestamp
            );
            CCIP.sendMessage{value:msg.value}(voteData);
        }

        voteStorage.upvote(postID, eventId, amount, msg.sender);
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 voteToken = IERC20(_tokenAddress);
        uint balance = voteToken.balanceOf(address(this));
        voteToken.transfer(owner(), balance);
    }

    function sendETH(address reciever, uint256 amount) external onlyOwner 
    {
        (bool success1, ) = reciever.call{value: amount}("");
        require(success1, "Can't send ETH to reciever");
    }

    receive() external payable {}
}
