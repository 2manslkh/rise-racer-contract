// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVelocityManager.sol";
import "./Registry.sol";

contract VelocityManager is IVelocityManager {
    // State variables
    mapping(address => uint256) private playerVelocity;
    Registry public immutable registry;

    // Events
    event VelocityAdded(address indexed player, uint256 amount);
    event VelocityReset(address indexed player);

    constructor(Registry _registry) {
        registry = _registry;
    }

    function addVelocity(address player, uint256 amount) external override {
        require(
            msg.sender == registry.getRiseRacers() ||
                msg.sender == registry.getUniverseManager(),
            "Only RiseRacers or UniverseManager can add velocity"
        );
        playerVelocity[player] += amount;
        emit VelocityAdded(player, amount);
    }

    function getCurrentVelocity(
        address player
    ) external view override returns (uint256) {
        return playerVelocity[player];
    }

    function resetVelocity(address player) external {
        require(
            msg.sender == registry.getUniverseManager(),
            "Only UniverseManager can reset velocity"
        );
        playerVelocity[player] = 0;
        emit VelocityReset(player);
    }
}
