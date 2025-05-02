// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRiseRacers.sol";
import "./interfaces/IUniverseManager.sol";
import "./interfaces/ICosmicParts.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IVelocityManager.sol";
import "./Registry.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/Pausable.sol";
import "./interfaces/IMilestones.sol";
import "./interfaces/IRiseCrystals.sol";

/// @title RiseRacers - Main game contract
/// @notice Implements the core game mechanics for Rise Racers
contract RiseRacers is IRiseRacers, Ownable, ReentrancyGuard, Pausable {
    // State variables
    mapping(address => PlayerInfo) private players;
    Registry public immutable registry;

    // Binding state
    mapping(address => address) private binderToBound;
    mapping(address => address) private boundToBinder;

    // Events
    event AddressBound(address indexed binder, address indexed boundAddress);
    event AddressUnbound(address indexed binder, address indexed boundAddress);
    event PlayerUpdated(address indexed player, PlayerInfo playerInfo);

    constructor(Registry _registry) Ownable(msg.sender) {
        registry = _registry;
    }

    // Implementation of IRiseRacers interface
    function click() external override nonReentrant whenNotPaused {
        PlayerInfo storage player = players[msg.sender];

        // Calculate velocity gain
        uint256 clickPower = getClickPower(msg.sender);
        uint256 velocityGain = clickPower;

        // Update player state
        player.totalClicks++;

        // Update velocity in VelocityManager
        IVelocityManager(registry.getVelocityManager()).addVelocity(
            msg.sender,
            velocityGain
        );

        player.velocity = IVelocityManager(registry.getVelocityManager())
            .getCurrentVelocity(msg.sender);

        uint8 currentMilestone = IMilestones(registry.getMilestoneTracker())
            .getCurrentMilestone(msg.sender);

        player.currentStage = currentMilestone;

        // Mint 1 crystal for the click
        IRiseCrystals(registry.getRiseCrystals()).mint(msg.sender, 1e18);

        // Mint extra crystals per turbo level
        uint256 turboLevel = ICosmicParts(registry.getCosmicParts())
            .getPartLevelByUser(msg.sender, ICosmicParts.PartType.Turbo);
        IRiseCrystals(registry.getRiseCrystals()).mint(msg.sender, turboLevel);

        // Check for milestones
        emit Click(msg.sender, velocityGain, player.velocity);
        emit PlayerUpdated(msg.sender, player);
    }

    function getPlayerInfo(
        address player
    ) external view override returns (PlayerInfo memory) {
        return players[player];
    }

    function getBaseClickPower(
        address player
    ) public view override returns (uint256) {
        // Get base click power (1) plus boosts from parts
        uint256 totalBoost = ICosmicParts(registry.getCosmicParts())
            .getTotalBoost(player);
        uint256 baseClickPower = 1 + totalBoost;

        return baseClickPower;
    }

    function getClickPower(address player) public view returns (uint256) {
        uint256 baseClickPower = getBaseClickPower(player);
        uint256 universeMultiplier = IUniverseManager(
            registry.getUniverseManager()
        ).getPlayerUniverseMultiplier(player);
        return baseClickPower * universeMultiplier;
    }

    // Admin functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
