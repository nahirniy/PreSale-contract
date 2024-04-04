// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolarGreen is ERC20, AccessControl {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant BLACKLISTER = keccak256("BLACKLISTER");

    uint public initiallySupply = 100000000 ether;

    mapping(address => bool) private _blacklist;

    constructor(
        address _owner,
        address _blacklister
    ) ERC20("Solar Green", "SGR") {
        _grantRole(ADMIN, _owner);
        _grantRole(BLACKLISTER, _blacklister);

        _mint(address(this), 50000000 ether);
    }

    function mint(address to, uint256 amount) public onlyRole(ADMIN) {
        _mint(to, amount);
    }

    function burn(uint value) public onlyRole(ADMIN) {
        _burn(address(this), value);
    }

    function addBlacklister(address _newBlacklister) public onlyRole(ADMIN) {
        _grantRole(BLACKLISTER, _newBlacklister);
    }

    function removeBlacklister(address _blacklister) public onlyRole(ADMIN) {
        _revokeRole(BLACKLISTER, _blacklister);
    }

    function addToBlacklist(address _to) public onlyRole(BLACKLISTER) {
        _blacklist[_to] = true;
    }

    function removeFromBlacklist(address _to) public onlyRole(BLACKLISTER) {
        _blacklist[_to] = false;
    }

    function isBlacklisted(address _to) public view returns (bool) {
        return _blacklist[_to];
    }
}
