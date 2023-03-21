// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

pragma solidity 0.8.17;

contract ERC20Mock is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e27);
    }

    function getCirculatingSupply() external view returns (uint256) {
        return 10000e18;
    }

    function underlying() external view returns (address) {
        return address(this);
    }

    function _reduceReserves() external returns (uint256) {
        return 0;
    }

    function burnFrom(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
