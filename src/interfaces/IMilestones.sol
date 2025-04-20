// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMilestones {
    struct Milestone {
        uint8 id;
        uint256 speedRequirement;
        string name;
        string description;
    }

    function getCurrentMilestone(address player) external view returns (uint8);

    function getCurrentMilestoneWithSpeed(
        address player
    ) external view returns (uint8 currentMilestone, uint256 currentSpeed);

    function getMilestoneDetails(
        uint8 milestoneId
    ) external view returns (Milestone memory milestone);
}
