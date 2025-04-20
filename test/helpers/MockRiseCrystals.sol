// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../src/RiseCrystals.sol";

contract MockRiseCrystals is RiseCrystals {
    constructor(address _registryAddress) RiseCrystals(_registryAddress) {}

    function testMint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function testBurn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
