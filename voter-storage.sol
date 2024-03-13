// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting is Ownable {
    mapping(uint256 => uint) public votes; // mapping image url to votes
    mapping(uint => uint256) public quantityToVotePrice; // X vote equal to 
    address public voteContract;
    event Voted(
        address voter,
        uint256 postID,
        uint256 eventId,
        uint256 amount,
        uint256 timestamp
    );

    modifier onlyVoteContract() {
        require(msg.sender == voteContract, "Not vote contract");
        _;
    }

    constructor(address _voteContract) Ownable(msg.sender) {
        voteContract = _voteContract;
    }

    function ChangeVoteContract(address _voteContract) external onlyOwner {
        voteContract = _voteContract;
    }

    function upvote(
        uint256 postID,
        uint256 eventId,
        uint256 amount,
        address sender
    ) public payable {
        require(amount > 0, "Amount must be greater than zero");
        votes[postID] += amount;

        emit Voted(
            msg.sender,
            postID,
            eventId,
            amount,
            block.timestamp
        );
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
