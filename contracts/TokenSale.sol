// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./SolarGreen.sol";

contract TokenSale {
    mapping(address => uint) private _userBalances;

    IERC20 public token;
    IERC20 public usdt;
    address public owner;
    uint public BASE_MULTIPLIER;
    uint public startAt;
    uint public endsAt;
    uint public availableTokens;
    uint public limitTokensPerUser;
    uint public tokenPrice;

    AggregatorV3Interface internal aggregatorInterface;

    event Bought(uint _amount, address indexed _buyer);
    // event TokenSaleEnded(uint _amoutUnpurchasedTokens, uint _endTime);

    constructor() {
        token = new SolarGreen(address(this));
        usdt = IERC20(address(0x1531BC5dE10618c511349f8007C08966E45Ce8ef));

        owner = msg.sender;

        availableTokens = token.balanceOf(address(this)) / 2;
        limitTokensPerUser = 50000 * BASE_MULTIPLIER;
        BASE_MULTIPLIER = 10 ** 18;

        startAt = block.timestamp;
        endsAt = 5 * 7 * 24 * 60 * 60 + startAt; // 5 weeks

        tokenPrice = (7 * BASE_MULTIPLIER) / 1000; // 0.007$
        aggregatorInterface = AggregatorV3Interface(
            address(0x694AA1769357215DE4FAC081bf1f309aDC325306)
        );
    }

    modifier onlyOwner() {
        require((msg.sender == owner), "not an owner");
        _;
    }

    function verifyPurchase(address _buyer, uint _amountTokens) private {
        uint _userTokens = _userBalances[_buyer] += _amountTokens;

        require(
            _userTokens <= limitTokensPerUser,
            "cant buy more than 50k token"
        );
        require(block.timestamp >= startAt, "sale has not started yet");
        require(block.timestamp < endsAt, "sale has ended");
        require(_amountTokens > 0, "not enough funds!");
        require(_amountTokens <= availableTokens, "not enough tokens");
    }

    function tokenPurchase(address _buyer, uint _amountTokens) private {
        token.transfer(_buyer, _amountTokens);
        availableTokens -= _amountTokens;
        _userBalances[_buyer] += _amountTokens;

        emit Bought(_amountTokens, _buyer);
    }

    function tokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function usdtBalance() public view returns (uint) {
        return usdt.balanceOf(address(this));
    }

    function setSaleEndTime(uint _newDuration) external onlyOwner {
        endsAt = _newDuration + startAt;
    }

    function setSaleStartTime(uint _startTime) external onlyOwner {
        startAt = _startTime;
    }

    function getAllowance() public view returns (uint value) {
        value = usdt.allowance(msg.sender, address(this));
    }

    function updateTokenPrice(uint _newPrice) external {
        tokenPrice = _newPrice;
    }

    function getLatestPrice() public view returns (uint) {
        (, int price, , , ) = aggregatorInterface.latestRoundData();
        price = (price * 10 ** 10);
        return uint(price);
    }

    function ethBuyHelper(uint _amount) external view returns (uint ethAmount) {
        uint256 usdPrice = _amount * tokenPrice;
        ethAmount = (usdPrice * BASE_MULTIPLIER) / getLatestPrice();
    }

    function usdtBuyHelper(uint _amount) external view returns (uint usdPrice) {
        usdPrice = _amount * tokenPrice;
    }

    function buyWithUSDT(uint _amount) external {
        uint usdPrice = _amount * tokenPrice;
        uint tokensToBuy = _amount * BASE_MULTIPLIER;

        verifyPurchase(msg.sender, tokensToBuy);
        require(getAllowance() >= usdPrice, "not approved enough tokens");

        usdt.transferFrom(msg.sender, address(this), usdPrice);

        tokenPurchase(msg.sender, tokensToBuy);
    }

    function buyWithEth(uint _amount) external payable {
        uint usdPrice = _amount * tokenPrice;
        uint ethAmount = (usdPrice * BASE_MULTIPLIER) / getLatestPrice();
        uint tokensToBuy = _amount * BASE_MULTIPLIER;

        verifyPurchase(msg.sender, tokensToBuy);
        require(msg.value >= ethAmount, "Less payment");

        uint excess = msg.value - ethAmount;
        if (excess > 0) payable(msg.sender).transfer(excess);

        tokenPurchase(msg.sender, tokensToBuy);
    }
}
