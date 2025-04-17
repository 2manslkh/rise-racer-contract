// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVelocityManager {
    function addVelocity(address player, uint256 amount) external;

    function getCurrentVelocity(address player) external view returns (uint256);

    function getCurrentSpeed(address player) external view returns (uint256);

    function checkSpeedMilestone(address player) external;

    function resetVelocity(address player) external;
}
