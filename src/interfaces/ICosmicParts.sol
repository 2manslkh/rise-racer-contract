// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICosmicParts {
    enum PartType {
        Engine,
        Turbo,
        Chassis,
        Wheels
    }

    enum Rarity {
        Common,
        Rare,
        Epic,
        Legendary
    }

    struct CosmicPart {
        PartType partType;
        Rarity rarity;
        uint256 baseBoost;
        uint256 percentageBoost;
    }

    function mintPart(address to, PartType partType, Rarity rarity) external;

    function getTotalBoost(
        address player
    ) external view returns (uint256 baseBoost, uint256 percentageBoost);

    function equipPart(uint256 tokenId) external;
}
