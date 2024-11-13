// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ISolarGreen} from "./ISolarGreen.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface ITokenSale {
    error InvalidPurchaseToken();
    error InvalidSaleToken();
    error InvalidPriceFeed();
    error SaleNotStarted();
    error SaleEnded();
    error SaleNotActive();
    error LimitExceeded();
    error InvalidAmount();
    error InsufficientBalance();
    error InsufficientPayment();
    error InvalidPrice();
    error VestingNotEnded();
    error ZeroClaimAmount();

    event Bought(uint256 _amount, address indexed _buyer);
    event Claimed(uint256 _amount, address indexed _holder);
    event SalePaused(uint256 _timestamp);
    event SaleUnPaused(uint256 _timestamp);
    event WithdrawPurchaseToken(uint256 _amount, uint256 _timestamp);
    event WithdrawEth(uint256 _amount, uint256 _timestamp);
    event UpdatedSaleEndTime(uint256 _newTime);
    event UpdatedVestingEndTime(uint256 _newTime);
    event UpdatedSaleTokenPrice(uint256 _newPrice);

    function userBalances(address) external view returns (uint256);
    function SALE_TOKEN() external view returns (ISolarGreen);
    function PURCHASE_TOKEN() external view returns (IERC20);
    function PURCHASE_TOKEN_PRECISION() external view returns (uint256);
    function limitSaleTokensPerUser() external view returns (uint256);
    function startAt() external view returns (uint256);
    function endsAt() external view returns (uint256);
    function vestingEnd() external view returns (uint256);
    function availableSaleTokens() external view returns (uint256);
    function saleTokenPrice() external view returns (uint256);
    function saleActive() external view returns (bool);
    function PRICE_FEED() external view returns (AggregatorV3Interface);

    function buyWithERC20(uint256 _amount) external;
    function buyWithNative(uint256 _amount) external payable;
    function claimTokens(address _holder) external;
    function startSale() external;
    function pauseSale() external;
    function unPauseSale() external;
    function updateSaleTokenPrice(uint256 _newPrice) external;
    function setSaleEndTime(uint256 _newDuration) external;
    function setVestingEndTime(uint256 _newTime) external;
    function getLatestPrice() external view returns (uint256);
    function getPurchaseTokenAmount(uint256 _amount) external view returns (uint256 purchaseTokenAmount);
    function getNativeTokenAmount(uint256 _amount) external view returns (uint256 nativeTokenAmount);
    function withdrawAllNativeToken() external;
    function withdrawNativeToken(address _to, uint256 _amount) external;
    function withdrawAllPurchaseToken() external;
    function withdrawTokens(address _token, address _to, uint256 _amount) external;
}