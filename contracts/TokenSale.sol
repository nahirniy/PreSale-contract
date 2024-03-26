// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SolarGreen.sol";

contract TokenSale {
    IERC20 public token;
    address public owner;
    uint public availableTokens;
    uint public saleStartTime;
    uint public saleEndTime;

    event Bought(uint _amount, address indexed _buyer);

    constructor() {
        token = new SolarGreen(address(this));
        owner = msg.sender;
        availableTokens = token.balanceOf(address(this)) / 2;
        saleEndTime = 5 * 7 * 24 * 60 * 60 + saleStartTime; // 5 week
        saleStartTime = block.timestamp;
    }

    modifier onlyOwner() {
        require((msg.sender == owner), "not an owner");
        _;
    }

    function tokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function setSaleEndTime(uint _newDuration) external onlyOwner {
        saleEndTime = _newDuration + saleStartTime;
    }

    receive() external payable {
        uint tokensToBuy = msg.value; // 1 token - 1 wei

        require(block.timestamp >= saleStartTime, "Sale has not started yet");
        require(block.timestamp < saleEndTime, "Sale has ended");
        require(tokensToBuy > 0, "not enough funds!");
        require(tokensToBuy <= 50000, "can't buy more than 50k token");
        require(tokensToBuy <= availableTokens, "not enough tokens");

        token.transfer(msg.sender, tokensToBuy);
        availableTokens -= tokensToBuy;

        emit Bought(tokensToBuy, msg.sender);
    }
}
