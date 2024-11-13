// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/// @title ISolarGreen
/// @notice Interface for the SolarGreen contract
interface ISolarGreen is IERC20 {
    /// @notice Error: Invalid owner address
    error InvalidOwner();
    /// @notice Error: Invalid address
    error InvalidAddress();
    /// @notice Error: Address is already blacklisted
    error AlreadyBlacklisted();
    /// @notice Error: Address is not blacklisted
    error NotBlacklisted();

    /// @notice Event emitted when an address is added to blacklist
    /// @param account The address that was blacklisted
    event Blacklisted(address indexed account);

    /// @notice Event emitted when an address is removed from blacklist
    /// @param account The address that was removed from blacklist
    event RemovedFromBlacklist(address indexed account);

    /// @notice Mints new tokens and allocates them to a specified account
    /// @param _to The address where the newly minted tokens will be allocated
    /// @param _amount The amount of tokens to mint
    function mint(address _to, uint256 _amount) external;

    /// @notice Adds the specified address to the blacklist
    /// @param _address The address to be added to the blacklist
    function addToBlacklist(address _address) external;

    /// @notice Removes the specified address from the blacklist
    /// @param _address The address to be removed from the blacklist
    function removeFromBlacklist(address _address) external;

    /// @notice Checks if an address is blacklisted
    /// @param account The address to check
    /// @return bool Returns true if the address is blacklisted
    function blacklist(address account) external view returns (bool);
}