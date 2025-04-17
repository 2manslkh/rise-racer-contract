// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRiseRacers.sol";
import "./interfaces/IMilestoneTracker.sol";
import "./interfaces/IUniverseManager.sol";
import "./interfaces/ICosmicParts.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IVelocityManager.sol";
import "./Registry.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/utils/Pausable.sol";

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

    constructor(Registry _registry) Ownable(msg.sender) {
        registry = _registry;
    }

    // --- Binding Logic ---

    /// @notice Binds the caller's address (binder) to a specified address (boundAddress).
    /// @dev Enforces a strict 1-to-1 mapping. Both binder and boundAddress must be unbound prior.
    /// @param _boundAddress The address to bind to. Cannot be address(0) or the caller's address.
    function bindAddress(address _boundAddress) external nonReentrant {
        require(
            _boundAddress != address(0),
            "RiseRacers: Bound address cannot be zero"
        );
        require(_boundAddress != msg.sender, "RiseRacers: Cannot bind to self");
        require(
            boundToBinder[_boundAddress] == address(0),
            "RiseRacers: Target address already bound by another"
        );

        binderToBound[msg.sender] = _boundAddress;
        boundToBinder[_boundAddress] = msg.sender;

        emit AddressBound(msg.sender, _boundAddress);
    }

    /// @notice Gets the address bound by a specific binder address.
    /// @param _binder The address of the binder.
    /// @return The address bound by the binder, or address(0) if none.
    function getBoundAddress(address _binder) external view returns (address) {
        return binderToBound[_binder];
    }

    /// @notice Gets the binder address associated with a specific bound address.
    /// @param _boundAddress The address that is bound.
    /// @return The address of the binder, or address(0) if the address is not bound.
    function getBinderAddress(
        address _boundAddress
    ) external view returns (address) {
        return boundToBinder[_boundAddress];
    }

    // --- Core Game Logic ---

    // Implementation of IRiseRacers interface
    function click() external override nonReentrant whenNotPaused {
        PlayerInfo storage player = players[msg.sender];

        // Calculate velocity gain
        uint256 clickPower = getClickPower(msg.sender);
        uint256 universeMultiplier = IUniverseManager(
            registry.getUniverseManager()
        ).getUniverseMultiplier(msg.sender);
        uint256 velocityGain = clickPower * universeMultiplier;

        // Update player state
        player.velocity += velocityGain;
        player.totalClicks++;

        // Update velocity in VelocityManager
        IVelocityManager(registry.getVelocityManager()).addVelocity(
            msg.sender,
            velocityGain
        );

        // Check for milestones
        IVelocityManager(registry.getVelocityManager()).checkSpeedMilestone(
            msg.sender
        );

        emit Click(msg.sender, velocityGain, player.velocity);
    }

    function getPlayerInfo(
        address player
    ) external view override returns (PlayerInfo memory) {
        return players[player];
    }

    function getClickPower(
        address player
    ) public view override returns (uint256) {
        // Check binding for the player whose power is being checked
        // Note: Depending on game design, you might want to enforce binding here too,
        // or only enforce it for the active click() action. Currently enforced only in click().
        // require(binderToBound[player] != address(0), "RiseRacers: Player address not bound");

        // Get base click power (1) plus boosts from parts
        (uint256 baseBoost, uint256 percentageBoost) = ICosmicParts(
            registry.getCosmicParts()
        ).getTotalBoost(player);
        uint256 baseClickPower = 1 + baseBoost;

        // Apply percentage boost
        if (percentageBoost > 0) {
            baseClickPower += (baseClickPower * percentageBoost) / 100;
        }

        return baseClickPower;
    }

    // Admin functions
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
