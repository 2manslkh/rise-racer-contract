// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniverseManager.sol";
import "./ICosmicParts.sol";
import "./IStaking.sol";
import "./IVelocityManager.sol";

/// @title IRiseRacers - Main interface for player interactions
/// @notice This interface serves as the primary entry point for all player actions
interface IRiseRacers {
    /// @notice Player information structure
    struct PlayerInfo {
        uint256 velocity; // Current velocity
        uint8 currentStage; // Current stage
        uint256 currentUniverse; // Current universe ID
        uint256 totalClicks; // Total number of clicks
        bool isStaking; // Whether player is staking
    }

    /// @notice Event emitted when a player clicks
    event Click(
        address indexed player,
        uint256 velocityGained,
        uint256 newTotalVelocity
    );

    /// @notice Event emitted when a player reaches a new milestone
    event MilestoneReached(
        address indexed player,
        uint256 milestoneId,
        string milestoneName
    );

    /// @notice Main click function to generate velocity
    /// @dev There should be a cooldown period between clicks
    function click() external;

    /// @notice Get player's current information
    /// @param player Address of the player
    /// @return PlayerInfo struct containing player's current state
    function getPlayerInfo(
        address player
    ) external view returns (PlayerInfo memory);

    /// @notice Get player's current click power (velocity per click)
    /// @param player Address of the player
    /// @return Amount of velocity gained per click
    function getClickPower(address player) external view returns (uint256);

    /// @notice Get player's base click power (velocity per click)
    /// @param player Address of the player
    /// @return Amount of velocity gained per click
    function getBaseClickPower(address player) external view returns (uint256);
}
