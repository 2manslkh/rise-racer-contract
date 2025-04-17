// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/IMilestoneTracker.sol";
import "./interfaces/IVelocityManager.sol";
import "./Registry.sol";

contract MilestoneTracker is IMilestoneTracker, ERC721URIStorage, Ownable {
    // State variables
    mapping(uint256 => Milestone) public milestones;
    mapping(address => uint256) public playerCurrentMilestone;
    mapping(address => mapping(uint256 => bool)) public achievedMilestones;
    mapping(address => mapping(uint256 => bool)) public hasClaimed;
    uint256 public nextMilestoneId;
    uint256 public nextTokenId;
    Registry public immutable registry;

    constructor(
        Registry _registry
    ) ERC721("RiseRacer Milestones", "RRM") Ownable(msg.sender) {
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
    ) external view override returns (uint256) {
        return playerCurrentMilestone[player];
    }

    function getCurrentMilestoneWithSpeed(
        address player
    ) external view returns (uint256 currentMilestone, uint256 currentSpeed) {
        currentMilestone = playerCurrentMilestone[player];
        currentSpeed = IVelocityManager(registry.getVelocityManager())
            .getCurrentSpeed(player);
    }

    function checkMilestoneAchievement(address player) external override {
        require(
            msg.sender == registry.getVelocityManager(),
            "Only VelocityManager can check achievements"
        );

        uint256 currentMilestoneId = playerCurrentMilestone[player];
        if (currentMilestoneId >= nextMilestoneId) return;

        Milestone storage targetMilestone = milestones[currentMilestoneId];
        uint256 currentSpeed = IVelocityManager(registry.getVelocityManager())
            .getCurrentSpeed(player);

        if (currentSpeed >= targetMilestone.speedRequirement) {
            playerCurrentMilestone[player] = currentMilestoneId + 1;
            achievedMilestones[player][currentMilestoneId] = true; // Store achievement for current milestone
        }
    }

    function claimMilestoneNFT(uint256 milestoneId) external override {
        require(
            achievedMilestones[msg.sender][milestoneId],
            "Milestone not achieved"
        );
        require(!hasClaimed[msg.sender][milestoneId], "Already claimed"); // New mapping

        _mint(msg.sender, milestoneId); // Mint using milestoneId as tokenId
        _setTokenURI(milestoneId, _generateTokenURI(milestoneId));
        hasClaimed[msg.sender][milestoneId] = true;
    }

    // Internal functions
    function _addMilestone(
        string memory name,
        string memory description,
        uint256 speedRequirement
    ) internal {
        milestones[nextMilestoneId] = Milestone({
            id: nextMilestoneId,
            speedRequirement: speedRequirement,
            name: name,
            description: description,
            achieved: false
        });
        nextMilestoneId++;
    }

    function _generateTokenURI(
        uint256 milestoneId
    ) internal view returns (string memory) {
        // In a real implementation, this would generate proper metadata
        // For now, we'll return a placeholder
        return string(abi.encodePacked("milestone/", milestoneId));
    }
}
