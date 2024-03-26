// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SolarGreen.sol";

contract TokenSale {
    IERC20 public token;
    address public owner;
    uint public availableTokens;
    uint public startAt;
    uint public endsAt;

    event Bought(uint _amount, address indexed _buyer);
    event TokenSaleEnded(uint _amoutUnpurchasedTokens, uint _endTime);

    constructor() {
        token = new SolarGreen(address(this));
        owner = msg.sender;
        availableTokens = token.balanceOf(address(this)) / 2;
        startAt = block.timestamp;
        endsAt = 5 * 7 * 24 * 60 * 60 + startAt; // 5 week
    }

    modifier onlyOwner() {
        require((msg.sender == owner), "not an owner");
        _;
    }

    function tokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function setSaleEndTime(uint _newDuration) external onlyOwner {
        endsAt = _newDuration + startAt;
    }

    function setSaleStartTime(uint _startTime) external onlyOwner {
        startAt = _startTime;
    }

    receive() external payable {
        uint tokensToBuy = msg.value; // 1 token - 1 wei

        if (availableTokens == 0 || block.timestamp >= endsAt) {
            emit TokenSaleEnded(availableTokens, endsAt);
        }

        require(block.timestamp >= startAt, "sale has not started yet");
        require(block.timestamp < endsAt, "sale has ended");
        require(tokensToBuy > 0, "not enough funds!");
        require(tokensToBuy <= 50000, "can't buy more than 50k token");
        require(tokensToBuy <= availableTokens, "not enough tokens");

        token.transfer(msg.sender, tokensToBuy);
        availableTokens -= tokensToBuy;

        emit Bought(tokensToBuy, msg.sender);
    }
}
