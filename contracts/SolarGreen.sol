// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ISolarGreen} from "./interfaces/ISolarGreen.sol";

/// @title SolarGreen
/// @notice ERC20 token with a blacklist feature
contract SolarGreen is ISolarGreen, ERC20, ERC20Burnable, AccessControl {
    /// @notice Role for the blacklister
    bytes32 public constant BLACKLISTER = keccak256("BLACKLISTER");
    /// @notice Initial supply of the token
    uint256 public initiallySupply = 100_000_000 ether;

    /// @notice Mapping to track blacklisted addresses
    mapping(address => bool) public blacklist;

    /// @notice Constructor for the SolarGreen contract
    /// @param _owner The address of the owner
    constructor(address _owner) ERC20("Solar Green", "SGR") {
        if (_owner == address(0)) revert InvalidOwner();
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(BLACKLISTER, _owner);

        _mint(_owner, initiallySupply);
    }

    /// @notice Mint new tokens and allocate them to a specified account
    /// @param _to The address where the newly minted tokens will be allocated
    /// @param _amount The amount of tokens to mint
    function mint(address _to, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(_to, _amount);
    }

    /// @notice Adds the specified address to the blacklist
    /// @param _address The address to be added to the blacklist
    function addToBlacklist(address _address) external onlyRole(BLACKLISTER) {
        if (_address == address(0)) revert InvalidAddress();
        if (blacklist[_address]) revert AlreadyBlacklisted();

        blacklist[_address] = true;
        emit Blacklisted(_address);
    }

    /// @notice Removes the specified address from the blacklist
    /// @param _address The address to be removed from the blacklist
    function removeFromBlacklist(address _address) external onlyRole(BLACKLISTER) {
        if (_address == address(0)) revert InvalidAddress();
        if (!blacklist[_address]) revert NotBlacklisted();

        blacklist[_address] = false;
        emit RemovedFromBlacklist(_address);
    }
}
