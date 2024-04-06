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
    uint public constant PRECISION = 10 ** 18;
    uint public constant startAt = 1710428400; // Thu Mar 14 2024 17:00:00
    uint public constant limitTokensPerUser = 50000 * PRECISION; // 50k
    uint public endsAt = startAt + 5 weeks;
    uint public vestingEnd = 1735682399; // Tue Dec 31 2024 23:59:59
    uint public availableTokens = 50000000 * PRECISION; // 50 mln
    bool public saleActive = false;

    AggregatorV3Interface internal aggregatorInterface;

    event Bought(uint _amount, address indexed _buyer);
    event Claimed(uint _amount, address indexed _holder);

    event SalePaused(uint _timestamp);
    event SaleUnPaused(uint _timestamp);

    event WithdrawUSDT(uint _amount, uint _timestamp);
    event WithdrawETH(uint _amount, uint _timestamp);

    event UpdatedSaleEndTime(uint _newTime);
    event UpdatedVestingEndTime(uint _newTime);

    event UpdatedTokenPrice(uint _newPrice);

    constructor(
        address _initialOwner,
        address _ustd,
        address _priceFeed,
        address _token,
        uint _tokenPrice
    ) Ownable(_initialOwner) {
        usdt = IERC20(_ustd);
        token = SolarGreen(_token);
        aggregatorInterface = AggregatorV3Interface(address(_priceFeed));

        tokenPrice = _tokenPrice;
    }

    /**
     * @dev Verifies the purchase conditions for the buyer.
     * @param _buyer The address of the buyer.
     * @param _amountTokens The amount of tokens to be purchased.
     */
    function _verifyPurchase(address _buyer, uint _amountTokens) internal view {
        require(
            block.timestamp >= startAt &&
                block.timestamp <= endsAt &&
                saleActive,
            "sale is not active"
        );
        require(
            _userBalances[_buyer] + _amountTokens <= limitTokensPerUser,
            "cant buy more than 50k"
        );
        require(!token.isBlacklisted(_buyer), "recipiant is blacklisted");
        require(_amountTokens > 0, "not enough funds!");
        require(_amountTokens <= availableTokens, "not enough tokens");
    }

    /**
     * @dev Handles the token purchase process.
     * @param _buyer The address of the buyer.
     * @param _amountTokens The amount of tokens to be purchased.
     */
    function _tokenPurchase(address _buyer, uint _amountTokens) internal {
        availableTokens -= _amountTokens;
        _userBalances[_buyer] += _amountTokens;

        emit Bought(_amountTokens, _buyer);
    }

    /**
     * @dev Retrieves the balance of tokens held by the contract.
     * @return The balance of tokens held by the contract.
     */
    function tokenBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Retrieves the balance of Ether held by the contract.
     * @return The balance of Ether held by the contract.
     */
    function ethBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * @dev Retrieves the balance of USDT held by the contract.
     * @return The balance of USDT held by the contract.
     */
    function usdtBalance() public view returns (uint) {
        return usdt.balanceOf(address(this));
    }

    /**
     * @dev Retrieves the balance of tokens held by a specific user.
     * @param _address The address of the user whose token balance is being checked.
     * @return The balance of tokens held by the specified user.
     */
    function checkUserBalance(address _address) external view returns (uint) {
        return _userBalances[_address];
    }

    /**
     * @dev Start the token sale. Initiates the token sale process.
     */
    function startSale() external onlyOwner {
        require(tokenBalance() > 0, "no tokens available for sale");
        require(
            tokenBalance() == availableTokens,
            "incorrect initial supply for sale"
        );

        saleActive = true;
    }

    /**
     * @dev Pause the token sale. Only the contract owner can pause the sale.
     */
    function pauseSale() external onlyOwner {
        require(saleActive, "sale has already been stopped");

        saleActive = false;
        emit SalePaused(block.timestamp);
    }

    /**
     * @dev Unpause the token sale. Only the contract owner can unpause the sale.
     */
    function unPauseSale() external onlyOwner {
        require(!saleActive, "sale has already been activated");

        saleActive = true;
        emit SaleUnPaused(block.timestamp);
    }

    /**
     * @dev Retrieves the amount of USDT tokens that the caller has approved the contract to spend on its behalf.
     * @return value The allowance for spending USDT tokens granted by the caller to the contract.
     */
    function getAllowance() internal view returns (uint value) {
        value = usdt.allowance(msg.sender, address(this));
    }

    /**
     * @dev Updates the price of the token.
     * @param _newPrice The new price of the token.
     */
    function updateTokenPrice(uint _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
        emit UpdatedTokenPrice(tokenPrice);
    }

    /**
     * @dev Sets the end time of the token sale.
     * @param _newDuration The new duration (in seconds) for the token sale.
     */
    function setSaleEndTime(uint _newDuration) external onlyOwner {
        endsAt = _newDuration + startAt;
        emit UpdatedSaleEndTime(endsAt);
    }

    /**
     * @dev Sets the end time of the vesting.
     * @param _newTime The new duration (in seconds) for the vesting end.
     */
    function setVestingEndTime(uint _newTime) external onlyOwner {
        vestingEnd = _newTime;
        emit UpdatedVestingEndTime(vestingEnd);
    }

    /**
     * @dev Retrieves the latest price of Ethereum in USDT from the price feed.
     * @return The latest price of Ethereum in USDT.
     */
    function getLatestPrice() public view returns (uint) {
        (, int price, , , ) = aggregatorInterface.latestRoundData();
        require(price >= 0, "Price cannot be negative");
        price = (price * 10 ** 10);
        return uint(price);
    }

    /**
     * @dev Calculates the equivalent amount in USDT for a given amount of tokens based on the current token price.
     * @param _amount The amount of tokens for which the equivalent USDT amount is calculated.
     * @return usdPrice The equivalent amount of tokens in USDT.
     */
    function usdtBuyHelper(uint _amount) public view returns (uint usdPrice) {
        usdPrice = (_amount * tokenPrice) / PRECISION;
    }

    /**
     * @dev Calculates the equivalent amount in Ethereum for a given amount of tokens based on the current token price.
     * @param _amount The amount of tokens for which the equivalent Ethereum amount is calculated.
     * @return ethAmount The equivalent amount of tokens in Ethereum.
     */
    function ethBuyHelper(uint _amount) public view returns (uint ethAmount) {
        uint usdPrice = usdtBuyHelper(_amount);
        ethAmount = (usdPrice * PRECISION) / getLatestPrice();
    }

    /**
     * @dev Allows users to buy tokens using USDT.
     * @param _amount The amount of tokens to purchase.
     */

    function buyWithUSDT(uint _amount) external {
        _verifyPurchase(msg.sender, _amount);

        uint usdPrice = usdtBuyHelper(_amount);
        require(getAllowance() >= usdPrice, "not approved enough tokens");

        usdt.transferFrom(msg.sender, address(this), usdPrice);

        _tokenPurchase(msg.sender, _amount);
    }

    /**
     * @dev Allows users to buy tokens using Ethereum.
     * @param _amount The amount of tokens to purchase.
     */
    function buyWithEth(uint _amount) external payable {
        _verifyPurchase(msg.sender, _amount);

        uint ethAmount = ethBuyHelper(_amount);
        require(msg.value >= ethAmount, "less payment");

        uint excess = msg.value - ethAmount;
        if (excess > 0) payable(msg.sender).transfer(excess);

        _tokenPurchase(msg.sender, _amount);
    }

    /**
     * @dev Allows token holders to claim their tokens after the vesting period ends.
     * @param _holder The address of the token holder.
     */
    function claimToken(address _holder) external {
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

    /**
     * @dev Allows the contract owner to withdraw ETH from the contract.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawETH(uint _amount) external onlyOwner {
        require(ethBalance() >= _amount, "insufficient ETH balance");

        payable(msg.sender).transfer(_amount);
    }

    /**
     * @dev Allows the contract owner to withdraw USDT from the contract.
     * @param _amount The amount of USDT to withdraw.
     */
    function withdrawUSDT(uint _amount) external onlyOwner {
        require(usdtBalance() >= _amount, "insufficient USDT balance");

        usdt.transfer(msg.sender, _amount);

        emit WithdrawUSDT(_amount, block.timestamp);
    }

    /**
     * @dev Allows the contract owner to withdraw tokens from the contract.
     * @param _amount The amount of tokens to withdraw.
     */

    function withdrawToken(uint _amount) external onlyOwner {
        require(tokenBalance() >= _amount, "insufficient token balance");

        token.transfer(msg.sender, _amount);

        emit WithdrawETH(_amount, block.timestamp);
    }
}
