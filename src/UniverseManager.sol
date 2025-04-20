// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUniverseManager.sol";
import "./interfaces/IVelocityManager.sol";
import "./Registry.sol";

contract UniverseManager is IUniverseManager {
    // State variables
    mapping(uint256 => Universe) public universes;
    mapping(address => uint256) public playerUniverses;
    uint256 public constant MAX_UNIVERSE = 5;
    IVelocityManager public immutable velocityManager;
    Registry public immutable registry;

    // Events
    event UniverseProgression(address indexed player, uint256 newUniverse);

    constructor(address _velocityManager, address _registry) {
        velocityManager = IVelocityManager(_velocityManager);
        registry = Registry(_registry);

        // Initialize universes starting from 0
        universes[0] = Universe({
            id: 0,
            multiplier: 1,
            badgeName: "Novice Racer"
        });
        universes[1] = Universe({
            id: 1,
            multiplier: 15, // 1.5x represented as 15 for integer math
            badgeName: "Speedster Badge"
        });
        universes[2] = Universe({
            id: 2,
            multiplier: 225, // 2.25x
            badgeName: "Speed Demon Badge"
        });
        universes[3] = Universe({
            id: 3,
            multiplier: 338, // 3.38x
            badgeName: "Speed Deity Badge"
        });
        universes[4] = Universe({
            id: 4,
            multiplier: 506, // 5.06x
            badgeName: "God of Speed, Hermes Badge"
        });
        universes[5] = Universe({
            id: 5,
            multiplier: 759, // 7.59x
            badgeName: "The fastest man alive badge"
        });
    }

    function getCurrentUniverse(
        address player
    ) external view override returns (uint256) {
        return playerUniverses[player];
    }

    function rebirth() external override {
        uint256 currentUniverse = playerUniverses[msg.sender];

        require(currentUniverse < MAX_UNIVERSE, "Already at max universe");
        require(
            velocityManager.getCurrentVelocity(msg.sender) >= 299792458,
            "Must reach light speed to rebirth"
        );

        uint256 newUniverse = currentUniverse + 1;
        playerUniverses[msg.sender] = newUniverse;

        // Reset player's velocity
        velocityManager.resetVelocity(msg.sender);

        emit UniverseProgression(msg.sender, newUniverse);
    }

    function getUniverseMultiplier(
        address player
    ) external view override returns (uint256) {
        return universes[playerUniverses[player]].multiplier;
    }
}
