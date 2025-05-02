// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICosmicParts {
    enum PartType {
        Engine,
        Turbo,
        Chassis,
        Wheels
    }

    struct CosmicPart {
        PartType partType;
        uint256 level;
        uint256 boost;
    }

    function upgradePart(PartType partType) external;

    function getTotalBoost(address player) external view returns (uint256);

    function getPartLevelByUser(
        address player,
        PartType partType
    ) external view returns (uint256);
}
