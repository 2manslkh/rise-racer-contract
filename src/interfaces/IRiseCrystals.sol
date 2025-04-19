// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface for the RiseCrystals ERC20 token
 * @dev Extends IERC20 and adds the mint function required by the Staking contract.
 */
interface IRiseCrystals is IERC20 {
    /**
     * @dev Mints `amount` tokens to `account`.
     *
     * Requirements:
     *
     * - Caller must have minting permissions.
     */
    function mint(address account, uint256 amount) external;

    function pay(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}
