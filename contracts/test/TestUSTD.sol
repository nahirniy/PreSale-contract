// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestUSTD is ERC20 {
    constructor() ERC20("United States Dollar Tether", "USDT") {
        _mint(address(this), 100000000000 * 10 ** decimals());
    }

    function mint() public {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}
