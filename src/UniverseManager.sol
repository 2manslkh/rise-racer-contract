// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IUniverseManager.sol";
import "./interfaces/IVelocityManager.sol";
import "./Registry.sol";
import {UD60x18, ud, powu, mul, uUNIT} from "@prb/math/UD60x18.sol";
import {convert} from "@prb/math/ud60x18/Conversions.sol";

contract UniverseManager is IUniverseManager {
    // Define Universe struct without multiplier
    struct UniverseInfo {
        uint256 id;
        string badgeName;
    }

    // State variables
    mapping(address => uint256) public playerUniverses;

    // Exponential Curve Constants
    uint256 public constant BASE_MULTIPLIER = 1 ether;
    uint256 public constant MULTIPLIER_GROWTH_FACTOR = 1500000000000000000;

    Registry public immutable registry;

    // Events
    event UniverseProgression(address indexed player, uint256 newUniverse);

    constructor(Registry _registry) {
        registry = Registry(_registry);
    }

    function getCurrentUniverse(
        address player
    ) external view override returns (uint256) {
        return playerUniverses[player];
    }

    function rebirth() external override {
        uint256 currentUniverse = playerUniverses[msg.sender];

        require(
            IVelocityManager(registry.getVelocityManager()).getCurrentVelocity(
                msg.sender
            ) >= 299792458,
            "Must reach light speed to rebirth"
        );

        uint256 newUniverse = currentUniverse + 1;
        playerUniverses[msg.sender] = newUniverse;

        // Reset player's velocity using the registry to get the VelocityManager address
        IVelocityManager(registry.getVelocityManager()).resetVelocity(
            msg.sender
        );

        emit UniverseProgression(msg.sender, newUniverse);
    }

    function getPlayerUniverseMultiplier(
        address player
    ) external view returns (uint256) {
        return getUniverseMultiplier(playerUniverses[player]);
    }

    // Calculate multiplier exponentially
    function getUniverseMultiplier(
        uint256 universeLevel
    ) public view returns (uint256) {
        if (universeLevel == 0) {
            return BASE_MULTIPLIER / 1 ether;
        }

        UD60x18 base = ud(BASE_MULTIPLIER);
        UD60x18 growthFactor = ud(MULTIPLIER_GROWTH_FACTOR);

        UD60x18 multiplier = mul(base, powu(growthFactor, universeLevel));

        return multiplier.unwrap() / uUNIT;
    }
}
