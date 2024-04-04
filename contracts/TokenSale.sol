// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SolarGreen.sol";

contract TokenSale is Ownable {
    mapping(address => uint) private _userBalances;

    SolarGreen public token;
    IERC20 public usdt;
    uint public tokenPrice;
    uint public PRECISION = 10 ** 18;
    uint public startAt = block.timestamp;
    uint public endsAt = startAt + 5 weeks;
    uint public vestingEnd = 1735696799; // 2024-12-31 23-59
    uint public availableTokens = 50000000 * PRECISION; // 50 mln
    uint public limitTokensPerUser = 50000 * PRECISION; // 50k

    AggregatorV3Interface internal aggregatorInterface;

    event Bought(uint _amount, address indexed _buyer);
    event Claimed(uint _amount, address indexed _holder);

    // 0x694AA1769357215DE4FAC081bf1f309aDC325306 priceFeed ETH/USD
    // 0x1531BC5dE10618c511349f8007C08966E45Ce8ef USTD 18 desimals

    constructor(
        address _initialOwner,
        address _ustd,
        address _priceFeed,
        uint _tokenPrice
    ) Ownable(_initialOwner) {
        token = new SolarGreen(_initialOwner, _initialOwner);
        usdt = IERC20(_ustd);

        tokenPrice = _tokenPrice;
        aggregatorInterface = AggregatorV3Interface(address(_priceFeed));
    }

    function setSaleEndTime(uint _newDuration) external onlyOwner {
        endsAt = _newDuration + startAt;
    }

    function _verifyPurchase(address _buyer, uint _amountTokens) internal view {
        uint _currentUserTokens = _userBalances[_buyer];
        uint _userTokens = _currentUserTokens += _amountTokens;

        require(!token.isBlacklisted(_buyer), "recipiant is blacklisted");
        require(_userTokens <= limitTokensPerUser, "cant buy more than 50k");
        require(block.timestamp >= startAt, "sale has not started yet");
        require(block.timestamp <= endsAt, "sale has ended");
        require(_amountTokens > 0, "not enough funds!");
        require(_amountTokens <= availableTokens, "not enough tokens");
    }

    function _tokenPurchase(address _buyer, uint _amountTokens) internal {
        availableTokens -= _amountTokens;
        _userBalances[_buyer] += _amountTokens;

        emit Bought(_amountTokens, _buyer);
    }

    function tokenBalance() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    function ethBalance() public view returns (uint) {
        return address(this).balance;
    }

    function usdtBalance() public view returns (uint) {
        return usdt.balanceOf(address(this));
    }

    function getAllowance() internal view returns (uint value) {
        value = usdt.allowance(msg.sender, address(this));
    }

    function updateTokenPrice(uint _newPrice) external {
        tokenPrice = _newPrice;
    }

    function getLatestPrice() public view returns (uint) {
        (, int price, , , ) = aggregatorInterface.latestRoundData();
        require(price >= 0, "Price cannot be negative");
        price = (price * 10 ** 10);
        return uint(price);
    }

    function ethBuyHelper(uint _amount) public view returns (uint ethAmount) {
        uint usdPrice = (_amount * tokenPrice) / PRECISION;
        ethAmount = (usdPrice * PRECISION) / getLatestPrice();
    }

    function usdtBuyHelper(uint _amount) public view returns (uint usdPrice) {
        usdPrice = (_amount * tokenPrice) / PRECISION;
    }

    function checkUserBalance(address _address) external view returns (uint) {
        return _userBalances[_address];
    }

    function buyWithUSDT(uint _amount) external {
        uint usdPrice = usdtBuyHelper(_amount);

        _verifyPurchase(msg.sender, _amount);
        require(getAllowance() >= usdPrice, "not approved enough tokens");

        usdt.transferFrom(msg.sender, address(this), usdPrice);

        _tokenPurchase(msg.sender, _amount);
    }

    function buyWithEth(uint _amount) external payable {
        uint ethAmount = ethBuyHelper(_amount);

        _verifyPurchase(msg.sender, _amount);
        require(msg.value >= ethAmount, "Less payment");

        uint excess = msg.value - ethAmount;
        if (excess > 0) payable(msg.sender).transfer(excess);

        _tokenPurchase(msg.sender, _amount);
    }

    function claimToken(address _holder) public {
        require(
            block.timestamp > vestingEnd,
            "token claim will be allowed after 2024-12-31"
        );

        uint _userTokens = _userBalances[_holder];
        require(_userTokens > 0, "zero claim amount");

        token.transfer(_holder, _userTokens);
        _userBalances[_holder] -= _userTokens;

        emit Claimed(_userTokens, _holder);
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "insufficient ETH balance");

        address payable owner = payable(owner());

        owner.transfer(amount);
    }

    function withdrawUSDT(uint amount) external onlyOwner {
        require(usdtBalance() >= amount, "insufficient USDT balance");

        address payable owner = payable(owner());

        usdt.transfer(owner, amount);
    }
}
