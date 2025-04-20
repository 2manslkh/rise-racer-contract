// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 claimedCrystals;
        uint256 lockEndTime;
    }

    function stakeETH() external payable;

    function unstakeETH() external;

    function distributePool() external;
}
