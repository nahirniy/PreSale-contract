// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolarGreen is ERC20, AccessControl {
    bytes32 public constant BLACKLISTER = keccak256("BLACKLISTER");

    uint public initiallySupply = 100000000 ether;

    mapping(address => bool) private _blacklist;

    constructor(
        address _owner,
        address _blacklister
    ) ERC20("Solar Green", "SGR") {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(BLACKLISTER, _blacklister);

        _mint(address(this), 50000000 ether);
    }

    /**
     * @dev Mint new tokens and allocate them to a specified account.
     * @param _to The address where the newly minted tokens will be allocated.
     * @param _amount The amount of tokens to mint.
     */
    function mint(
        address _to,
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(_to, _amount);
    }

    /**
     * @dev Burn tokens from the contract's balance.
     * @param value The amount of tokens to burn.
     */
    function burn(uint value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(address(this), value);
    }

    /**
     *@dev Assigns the role of a blacklister to a new address, granting authority to add addresses to the blacklist.
     *@param _newBlacklister The address to be assigned the role of a blacklister.
     */
    function addBlacklister(
        address _newBlacklister
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(BLACKLISTER, _newBlacklister);
    }

    /**
     * @dev Removes the role of a blacklister from a specified address, thereby revoking their authority to manage the blacklist.
     * @param _blacklister The address from which to remove the role of blacklister.
     */
    function removeBlacklister(
        address _blacklister
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(BLACKLISTER, _blacklister);
    }

    /**
     * @dev Adds the specified address to the blacklist.
     * @param _address The address to be added to the blacklist.
     */
    function addToBlacklist(address _address) external onlyRole(BLACKLISTER) {
        _blacklist[_address] = true;
    }

    /**
     * @dev Removes the specified address from the blacklist.
     * @param _address The address to be removed from the blacklist.
     */
    function removeFromBlacklist(
        address _address
    ) external onlyRole(BLACKLISTER) {
        _blacklist[_address] = false;
    }

    /**
     * @dev Checks if the specified address is blacklisted.
     * @param _address The address to be checked.
     * @return Whether the address is blacklisted or not.
     */
    function isBlacklisted(address _address) external view returns (bool) {
        return _blacklist[_address];
    }
}
