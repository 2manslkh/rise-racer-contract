// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/access/Ownable.sol";
import "./interfaces/IVelocityManager.sol";
import "./Registry.sol";
import "./interfaces/IMilestones.sol";

contract MilestoneTracker is IMilestones, Ownable {
    // State variables
    mapping(uint8 => Milestone) public milestones;
    uint8 public nextMilestoneId = 1;
    Registry public immutable registry;

    constructor(Registry _registry) Ownable(msg.sender) {
        registry = _registry;

        _addMilestone(
            "Ignition",
            "Kick off your journey with a modest burst of speed.",
            50
        );
        _addMilestone(
            "Sound Barrier",
            "Smash through the barrier that once defined high-speed travel.",
            343
        );
        _addMilestone(
            "Suborbital Flight",
            "Experience your first taste of spacebound velocity.",
            1000
        );
        _addMilestone(
            "Orbital Velocity",
            "Reach the speed necessary to achieve low Earth orbit.",
            7800
        );
        _addMilestone(
            "Escape Velocity",
            "Break free from Earths gravitational pull.",
            11200
        );
        _addMilestone(
            "Initial Cosmic Leap",
            "Take a significant step into the cosmic arena.",
            299792
        );
        _addMilestone(
            "Rapid Acceleration",
            "Accelerate dramatically as you leave the familiar behind.",
            2997925
        );
        _addMilestone(
            "Hyper Drive",
            "Engage your hyper drive and begin interstellar travel.",
            29979246
        );

        _addMilestone(
            "Cosmic Sprint",
            "Pick up the pace with a burst that pushes you further than ever before.",
            74948115
        );
        _addMilestone(
            "Superluminal Approach",
            "Reach the midpoint of your journey to the cosmic barrier.",
            149896229
        ); // ~50% c
        // Background 6
        _addMilestone(
            "Near Light-Speed",
            "Nudge closer to the ultimate limit as you edge near light speed.",
            269813212
        ); // ~90% c
        _addMilestone(
            "Final Thrust",
            "Give your final burst to prepare for the ultimate transformation.",
            296794533
        ); // ~99% c
        _addMilestone(
            "Light Speed Achievement",
            "Achieve the legendary milestone-breaking the ultimate speed barrier.",
            299792458
        );
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
