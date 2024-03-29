// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SolarGreen is ERC20, ERC20Burnable, Ownable {
    mapping(address => bool) private _blacklist;

    constructor(
        address initialOwner
    ) ERC20("Solar Green", "SGR") Ownable(initialOwner) {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function addToBlacklist(address _to) public onlyOwner {
        _blacklist[_to] = true;
    }

    function removeFromBlacklist(address _to) public onlyOwner {
        _blacklist[_to] = false;
    }

    function isBlacklisted(address _to) public view returns (bool) {
        return _blacklist[_to];
    }

    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        require(!isBlacklisted(to), "recipiant is blacklisted");

        return super.transfer(to, value);
    }
}
