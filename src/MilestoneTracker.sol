// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/access/Ownable.sol";
import "./interfaces/IVelocityManager.sol";
import "./Registry.sol";
import "./interfaces/IMilestones.sol";

contract MilestoneTracker is IMilestones, Ownable {
    // State variables
    mapping(uint8 => Milestone) public milestones;
    mapping(address => uint8) public playerCurrentMilestone;
    mapping(address => mapping(uint8 => bool)) public hasClaimed;
    uint8 public nextMilestoneId;
    Registry public immutable registry;

    constructor(Registry _registry) Ownable(msg.sender) {
        registry = _registry;
        // Initialize milestones
        _addMilestone("Sound Barrier", "Break the sound barrier", 343);
        _addMilestone(
            "Escape Velocity",
            "Break free from Earth's gravity",
            11200
        );
        _addMilestone("1% Light Speed", "Reach 1% of light speed", 2997925);
        _addMilestone("10% Light Speed", "Reach 10% of light speed", 29979246);
        _addMilestone("50% Light Speed", "Reach 50% of light speed", 149896229);
        _addMilestone("90% Light Speed", "Reach 90% of light speed", 269813212);
        _addMilestone("99% Light Speed", "Reach 99% of light speed", 296794533);
        _addMilestone("99.99% Light Speed", "Almost there!", 299762479);
        _addMilestone("Light Speed", "Achieve the speed of light!", 299792458);
    }

    function getCurrentMilestone(
        address player
    ) external view override returns (uint8) {
        (uint8 currentMilestone, ) = _calculateMilestone(player);
        return currentMilestone;
    }

    function getCurrentMilestoneWithSpeed(
        address player
    ) external view returns (uint8 currentMilestone, uint256 currentSpeed) {
        (currentMilestone, currentSpeed) = _calculateMilestone(player);
    }

    function getMilestoneDetails(
        uint8 milestoneId
    ) external view returns (Milestone memory milestone) {
        return milestones[milestoneId];
    }

    // Internal functions
    function _calculateMilestone(
        address player
    ) internal view returns (uint8 currentMilestone, uint256 currentSpeed) {
        currentSpeed = IVelocityManager(registry.getVelocityManager())
            .getCurrentVelocity(player);

        if (currentSpeed < milestones[0].speedRequirement) {
            return (0, currentSpeed);
        }

        // Loop backwards from highest milestone to find the highest one achieved
        for (uint8 i = nextMilestoneId - 1; i > 0; i--) {
            if (currentSpeed >= milestones[i].speedRequirement) {
                return (i, currentSpeed);
            }
        }

        // If we get here, the player has achieved at least milestone 0
        return (0, currentSpeed);
    }

    function _addMilestone(
        string memory name,
        string memory description,
        uint256 speedRequirement
    ) internal {
        milestones[nextMilestoneId] = Milestone({
            id: nextMilestoneId,
            speedRequirement: speedRequirement,
            name: name,
            description: description
        });
        nextMilestoneId++;
    }
}
