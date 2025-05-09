// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniverseManager {
    struct Universe {
        uint256 id;
        uint256 multiplier;
        string badgeName;
    }

    function getCurrentUniverse(address player) external view returns (uint256);

    function rebirth() external;

    function getUniverseMultiplier(
        uint256 universeLevel
    ) external view returns (uint256);

    function getPlayerUniverseMultiplier(
        address player
    ) external view returns (uint256);
}
