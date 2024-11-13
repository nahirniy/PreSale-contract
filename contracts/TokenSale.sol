// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISolarGreen} from "./interfaces/ISolarGreen.sol";
import {ITokenSale} from "./interfaces/ITokenSale.sol";

/// @title TokenSale
/// @notice The TokenSale contract allows users to buy SALE_TOKENs using PURCHASE_TOKEN.
contract TokenSale is Ownable, ITokenSale {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public userBalances;

    ISolarGreen public immutable SALE_TOKEN;
    IERC20 public immutable PURCHASE_TOKEN;
    uint256 public immutable PURCHASE_TOKEN_PRECISION;

    uint256 public constant limitSaleTokensPerUser = 50_000 ether;
    uint256 public constant startAt = 1710428400; // Thu Mar 14 2024 17:00:00
    uint256 public endsAt = startAt + 5 weeks;
    uint256 public vestingEnd = 1735682399; // Tue Dec 31 2024 23:59:59
    uint256 public availableSaleTokens = 50_000_000 ether;
    uint256 public saleTokenPrice;
    bool public saleActive = false;

    /// @notice The price feed for the purchase token.
    AggregatorV3Interface public immutable PRICE_FEED;

    /// @notice Verifies the purchase conditions for the buyer.
    /// @param _buyer The address of the buyer.
    /// @param _amountSaleTokens The amount of SALE_TOKENs to be purchased.      
    modifier checkConditionsForPurchase(address _buyer, uint256 _amountSaleTokens) {
        uint256 currentTime = block.timestamp;
        if (currentTime < startAt) revert SaleNotStarted();
        if (currentTime > endsAt) revert SaleEnded();
        if (!saleActive) revert SaleNotActive();
        if (userBalances[_buyer] + _amountSaleTokens > limitSaleTokensPerUser) revert LimitExceeded();
        if (_amountSaleTokens == 0) revert InvalidAmount();
        if (_amountSaleTokens > availableSaleTokens) revert InsufficientBalance();

        _;
    }

    /// @notice Initializes the TokenSale contract.
    /// @param _initialOwner The address of the initial owner.
    /// @param _purchaseToken The address of the purchase token.
    /// @param _priceFeed The address of the price feed.
    /// @param _saleToken The address of the sale token.
    /// @param _saleTokenPrice The price of the sale token.
    constructor(
        address _initialOwner,
        address _purchaseToken,
        address _priceFeed,
        address _saleToken,
        uint256 _saleTokenPrice
    ) Ownable(_initialOwner) {
        if (!_isContract(_purchaseToken)) revert InvalidPurchaseToken();
        if (!_isContract(_saleToken)) revert InvalidSaleToken();
        if (!_isContract(_priceFeed)) revert InvalidPriceFeed();

        PURCHASE_TOKEN = IERC20(_purchaseToken);
        SALE_TOKEN = ISolarGreen(_saleToken);
        PRICE_FEED = AggregatorV3Interface(_priceFeed);
        PURCHASE_TOKEN_PRECISION = 10 ** IERC20Metadata(_purchaseToken).decimals();

        saleTokenPrice = _saleTokenPrice;
    }

    /// @notice Allows users to buy SALE_TOKENs using PURCHASE_TOKEN.
    /// @param _amount The amount of SALE_TOKENs to purchase.
    function buyWithERC20(uint256 _amount) external checkConditionsForPurchase(msg.sender, _amount) {
        uint256 purchaseTokenAmount = getPurchaseTokenAmount(_amount);
        PURCHASE_TOKEN.safeTransferFrom(msg.sender, address(this), purchaseTokenAmount);

        availableSaleTokens -= _amount;
        userBalances[msg.sender] += _amount;
        emit Bought(_amount, msg.sender);
    }

    /// @notice Allows users to buy SALE_TOKENs using Native Token.
    /// @param _amount The amount of SALE_TOKENs to purchase.
    function buyWithNative(uint256 _amount) external payable checkConditionsForPurchase(msg.sender, _amount) {
        uint256 nativeTokenAmount = getNativeTokenAmount(_amount);
        if (msg.value < nativeTokenAmount) revert InsufficientPayment();

        uint256 excess = msg.value - nativeTokenAmount;
        if (excess > 0) payable(msg.sender).transfer(excess);

        availableSaleTokens -= _amount;
        userBalances[msg.sender] += _amount;
        emit Bought(_amount, msg.sender);
    }

    /// @notice Allows SALE_TOKEN holders to claim their SALE_TOKENs after the vesting period ends.
    /// @param _holder The address of the SALE_TOKEN holder.
    function claimTokens(address _holder) external {
        if (block.timestamp < vestingEnd) revert VestingNotEnded();

        uint256 _userSaleTokens = userBalances[_holder];
        if (_userSaleTokens == 0) revert ZeroClaimAmount();

        userBalances[_holder] -= _userSaleTokens;
        SALE_TOKEN.transfer(_holder, _userSaleTokens);

        emit Claimed(_userSaleTokens, _holder);
    }

    /// @notice Starts the SALE_TOKEN sale.
    function startSale() external onlyOwner {
        if (SALE_TOKEN.balanceOf(address(this)) < availableSaleTokens) revert InsufficientBalance();

        saleActive = true;
    }

    /// @notice Pauses the SALE_TOKEN sale.
    function pauseSale() external onlyOwner {
        if (!saleActive) revert SaleNotActive();

        saleActive = false;
        emit SalePaused(block.timestamp);
    }

    /// @notice Unpauses the SALE_TOKEN sale.
    function unPauseSale() external onlyOwner {
        if (saleActive) revert SaleNotActive();

        saleActive = true;
        emit SaleUnPaused(block.timestamp);
    }

    /// @notice Updates the price of the SALE_TOKEN.
    /// @param _newPrice The new price of the SALE_TOKEN.
    function updateSaleTokenPrice(uint256 _newPrice) external onlyOwner {
        saleTokenPrice = _newPrice;
        emit UpdatedSaleTokenPrice(saleTokenPrice);
    }

    /// @notice Sets the end time of the SALE_TOKEN sale.
    /// @param _newDuration The new duration (in seconds) for the SALE_TOKEN sale.
    function setSaleEndTime(uint256 _newDuration) external onlyOwner {
        endsAt = _newDuration + startAt;
        emit UpdatedSaleEndTime(endsAt);
    }

    /// @notice Sets the end time of the vesting.
    /// @param _newTime The new duration (in seconds) for the vesting end.
    function setVestingEndTime(uint256 _newTime) external onlyOwner {
        vestingEnd = _newTime;
        emit UpdatedVestingEndTime(vestingEnd);
    }

    /// @notice Retrieves the latest price of Native Token in PURCHASE_TOKEN from the price feed.
    /// @return The latest price of Native Token in PURCHASE_TOKEN.
    function getLatestPrice() public view returns (uint256) {
        (, int price, , , ) = PRICE_FEED.latestRoundData();
        if (price < 0) revert InvalidPrice();
        price = (price * 10 ** 10);
        return uint256(price);
    }

    /// @notice calculates the equivalent amount in PURCHASE_TOKEN for a given amount of SALE_TOKENs based on the current SALE_TOKEN price.
    /// @param _amount The amount of SALE_TOKENs for which the equivalent PURCHASE_TOKEN amount is calculated.
    /// @return purchaseTokenAmount The equivalent amount of SALE_TOKENs in PURCHASE_TOKEN.
    function getPurchaseTokenAmount(uint256 _amount) public view returns (uint256 purchaseTokenAmount) {
        purchaseTokenAmount = (_amount * saleTokenPrice) / PURCHASE_TOKEN_PRECISION;
    }

    /// @notice Calculates the equivalent amount in Native Token for a given amount of SALE_TOKENs based on the current SALE_TOKEN price.
    /// @param _amount The amount of SALE_TOKENs for which the equivalent Native Token amount is calculated.
    /// @return nativeTokenAmount The equivalent amount of SALE_TOKENs in Native Token.
    function getNativeTokenAmount(uint256 _amount) public view returns (uint256 nativeTokenAmount) {
        uint256 purchaseTokenAmount = getPurchaseTokenAmount(_amount);
        nativeTokenAmount = (purchaseTokenAmount * PURCHASE_TOKEN_PRECISION) / getLatestPrice();
    }

    /// @notice Allows the contract owner to withdraw all native token from the contract.
    function withdrawAllNativeToken() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Allows the contract owner to withdraw native token from the contract.
    /// @param _to The address to transfer the token to.
    /// @param _amount The amount of the token to withdraw.
    function withdrawNativeToken(address _to, uint256 _amount) public onlyOwner {
        payable(_to).transfer(_amount);
    }

    /// @notice Allows the contract owner to withdraw PURCHASE_TOKEN from the contract.
    function withdrawAllPurchaseToken() public onlyOwner {
        PURCHASE_TOKEN.safeTransfer(msg.sender, PURCHASE_TOKEN.balanceOf(address(this)));
    }

    /// @notice Allows the contract owner to withdraw any ERC20 token from the contract.
    /// @param _token The address of the token to withdraw.
    /// @param _to The address to transfer the token to.
    /// @param _amount The amount of the token to withdraw.
    function withdrawTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice Checks if an address is a contract.
    /// @param _address The address to check.
    /// @return true if the address is a contract, false otherwise.
    function _isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }
}
