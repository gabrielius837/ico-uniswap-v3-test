//SPDX-License-Identifier: Unlicense
pragma solidity >= 0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

    }
    
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}