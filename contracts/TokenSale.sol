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

    constructor(
        address _initialOwner,
        address _ustd,
        address _priceFeed,
        address _token,
        uint _tokenPrice
    ) Ownable(_initialOwner) {
        usdt = IERC20(_ustd);

        token = SolarGreen(_token);
        tokenPrice = _tokenPrice;
        aggregatorInterface = AggregatorV3Interface(address(_priceFeed));
    }

    function _verifyPurchase(address _buyer, uint _amountTokens) internal view {
        uint _currentUserTokens = _userBalances[_buyer];
        uint _newUserTokens = _currentUserTokens += _amountTokens;

        require(
            block.timestamp >= startAt && block.timestamp <= endsAt,
            "sale is not active"
        );
        require(!token.isBlacklisted(_buyer), "recipiant is blacklisted");
        require(_newUserTokens <= limitTokensPerUser, "cant buy more than 50k");
        require(_amountTokens > 0, "not enough funds!");
        require(_amountTokens <= availableTokens, "not enough tokens");
    }

    function _tokenPurchase(address _buyer, uint _amountTokens) internal {
        availableTokens -= _amountTokens;
        _userBalances[_buyer] += _amountTokens;

        emit Bought(_amountTokens, _buyer);
    }

    function tokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function ethBalance() public view returns (uint) {
        return address(this).balance;
    }

    function usdtBalance() public view returns (uint) {
        return usdt.balanceOf(address(this));
    }

    function checkUserBalance(address _address) external view returns (uint) {
        return _userBalances[_address];
    }

    function getAllowance() internal view returns (uint value) {
        value = usdt.allowance(msg.sender, address(this));
    }

    function updateTokenPrice(uint _newPrice) external {
        tokenPrice = _newPrice;
    }

    function setSaleEndTime(uint _newDuration) external onlyOwner {
        endsAt = _newDuration + startAt;
    }

    function getLatestPrice() public view returns (uint) {
        (, int price, , , ) = aggregatorInterface.latestRoundData();
        require(price >= 0, "Price cannot be negative");
        price = (price * 10 ** 10);
        return uint(price);
    }

    function usdtBuyHelper(uint _amount) public view returns (uint usdPrice) {
        usdPrice = (_amount * tokenPrice) / PRECISION;
    }

    function ethBuyHelper(uint _amount) public view returns (uint ethAmount) {
        uint usdPrice = usdtBuyHelper(_amount);
        ethAmount = (usdPrice * PRECISION) / getLatestPrice();
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
        require(msg.value >= ethAmount, "less payment");

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

    function withdrawETH(uint _amount) external onlyOwner {
        require(ethBalance() >= _amount, "insufficient ETH balance");

        payable(msg.sender).transfer(_amount);
    }

    function withdrawUSDT(uint _amount) external onlyOwner {
        require(usdtBalance() >= _amount, "insufficient USDT balance");

        usdt.transfer(msg.sender, _amount);
    }

    function withdrawToken(uint _amount) external onlyOwner {
        require(tokenBalance() >= _amount, "insufficient token balance");

        token.transfer(msg.sender, _amount);
    }
}
