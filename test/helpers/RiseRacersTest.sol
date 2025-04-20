// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/RiseRacers.sol";
import "../../src/MilestoneTracker.sol";
import "../../src/UniverseManager.sol";
import "../../src/CosmicParts.sol";
import "../../src/Staking.sol";
import "../../src/VelocityManager.sol";
import "../../src/Registry.sol";
import "../../src/RiseCrystals.sol";

abstract contract RiseRacersTest is Test {
    // Core protocol contracts
    RiseRacers public game;
    MilestoneTracker public milestoneTracker;
    UniverseManager public universeManager;
    CosmicParts public cosmicParts;
    Staking public staking;
    VelocityManager public velocityManager;
    Registry public registry;
    RiseCrystals public riseToken;

    // Test addresses
    address public constant PLAYER_ONE = address(0xabc);
    address public constant PLAYER_TWO = address(0xdef);
    address public constant OWNER = address(0x1234);

    function setUp() public virtual {
        // Set up owner
        vm.startPrank(OWNER);

        // Create mock addresses for initial registry setup
        address mockRiseRacers = address(0x1);
        address mockMilestoneTracker = address(0x2);
        address mockUniverseManager = address(0x3);
        address mockVelocityManager = address(0x4);
        address mockCosmicParts = address(0x5);
        address mockStaking = address(0x6);
        address mockRiseCrystals = address(0x7);

        // Deploy Registry with mock addresses first
        registry = new Registry(
            mockRiseRacers,
            mockMilestoneTracker,
            mockUniverseManager,
            mockVelocityManager,
            mockCosmicParts,
            mockStaking,
            mockRiseCrystals
        );

        // Deploy contracts that don't need registry
        cosmicParts = new CosmicParts(registry);
        staking = new Staking(registry);

        // Deploy contracts with registry dependencies
        milestoneTracker = new MilestoneTracker(registry);
        velocityManager = new VelocityManager(registry);
        universeManager = new UniverseManager(
            address(velocityManager),
            address(registry)
        );

        riseToken = new RiseCrystals(address(registry));

        // Deploy main game contract with registry
        game = new RiseRacers(registry);

        // Update registry with actual contract addresses
        registry.updateContract(registry.RISE_RACERS(), address(game));
        registry.updateContract(
            registry.MILESTONE_TRACKER(),
            address(milestoneTracker)
        );
        registry.updateContract(
            registry.UNIVERSE_MANAGER(),
            address(universeManager)
        );
        registry.updateContract(
            registry.VELOCITY_MANAGER(),
            address(velocityManager)
        );
        registry.updateContract(registry.COSMIC_PARTS(), address(cosmicParts));
        registry.updateContract(registry.STAKING(), address(staking));
        registry.updateContract(registry.RISE_CRYSTALS(), address(riseToken));
        vm.stopPrank();

        // Give test players some ETH
        vm.deal(PLAYER_ONE, 10 ether);
        vm.deal(PLAYER_TWO, 10 ether);
    }

    // Helper functions
    function addVelocity(address player, uint256 amount) internal {
        vm.startPrank(address(game));
        velocityManager.addVelocity(player, amount);
        vm.stopPrank();
    }

    function reachLightSpeed(address player) internal {
        addVelocity(player, 299792458); // Speed of light in m/s
    }
}
