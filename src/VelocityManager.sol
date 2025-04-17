// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVelocityManager.sol";
import "./interfaces/IMilestoneTracker.sol";
import "./Registry.sol";

contract VelocityManager is IVelocityManager {
    // State variables
    mapping(address => uint256) private playerVelocity;
    IMilestoneTracker public immutable milestoneTracker;
    Registry public immutable registry;

    // Events
    event VelocityAdded(address indexed player, uint256 amount);
    event VelocityReset(address indexed player);

    constructor(address _milestoneTracker, address _registry) {
        milestoneTracker = IMilestoneTracker(_milestoneTracker);
        registry = Registry(_registry);
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

    function getCurrentSpeed(
        address player
    ) external view override returns (uint256) {
        // In our game, velocity equals speed (in m/s)
        return playerVelocity[player];
    }

    function checkSpeedMilestone(address player) external override {
        require(
            msg.sender == registry.getRiseRacers(),
            "Only RiseRacers can check milestones"
        );
        milestoneTracker.checkMilestoneAchievement(player);
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
