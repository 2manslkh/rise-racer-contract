// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMilestones is IERC1155 {
    struct Milestone {
        uint256 id;
        uint256 speedRequirement;
        string name;
        string description;
        bool mintable;
    }

    // Events
    event MilestoneAchieved(address indexed player, uint256 milestoneId);
    event MilestoneNFTMinted(
        address indexed player,
        uint256 milestoneId,
        uint256 amount
    );

    // Functions
    function getMilestoneDetails(
        uint256 milestoneId
    )
        external
        view
        returns (
            uint256 speedRequirement,
            string memory name,
            string memory description,
            bool mintable
        );

    function checkAchievement(
        address player
    ) external returns (uint256 currentMilestone);

    function mintAchievement(address player, uint256 milestoneId) external;

    // ERC1155 Override views
    function uri(uint256 milestoneId) external view returns (string memory);
}
