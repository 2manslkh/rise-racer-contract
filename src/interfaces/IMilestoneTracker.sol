// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMilestoneTracker {
    struct Milestone {
        uint256 id;
        uint256 speedRequirement;
        string name;
        string description;
        bool achieved;
    }

    function getCurrentMilestone(
        address player
    ) external view returns (uint256);

    function checkMilestoneAchievement(address player) external;

    function claimMilestoneNFT(uint256 milestoneId) external;
}
