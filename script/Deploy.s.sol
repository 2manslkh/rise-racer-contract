// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/RiseRacers.sol";
import "../src/MilestoneTracker.sol";
import "../src/UniverseManager.sol";
import "../src/CosmicParts.sol";
import "../src/Staking.sol";
import "../src/VelocityManager.sol";
import "../src/Registry.sol";
import "../src/RiseCrystals.sol";

contract DeployScript is Script {
    function run() external {
        // Get deployment private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // If deploying locally, use a default private key
        if (block.chainid == 31337) {
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy contracts that don't need registry first
        Staking staking = new Staking();

        // Step 2: Deploy Registry with temporary addresses
        Registry registry = new Registry(
            address(1), // temporary RiseRacers
            address(2), // temporary MilestoneTracker
            address(3), // temporary UniverseManager
            address(4), // temporary VelocityManager
            address(5), // temporary CosmicParts
            address(staking), // temporary Staking
            address(7) // temporary RiseCrystals
        );

        // Step 3: Deploy contracts that need registry
        MilestoneTracker milestoneTracker = new MilestoneTracker(registry);
        VelocityManager velocityManager = new VelocityManager(
            address(milestoneTracker),
            address(registry)
        );
        UniverseManager universeManager = new UniverseManager(
            address(velocityManager),
            address(registry)
        );

        CosmicParts cosmicParts = new CosmicParts(address(registry));
        RiseCrystals riseCrystals = new RiseCrystals(address(registry));
        // Step 4: Deploy main game contract
        RiseRacers game = new RiseRacers(registry);

        // Step 5: Update registry with actual addresses
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
        registry.updateContract(
            registry.RISE_CRYSTALS(),
            address(riseCrystals)
        );
        vm.stopBroadcast();

        // Log deployed addresses
        console.log("Deployed contracts:");
        console.log("RiseRacers:", address(game));
        console.log("Registry:", address(registry));
        console.log("MilestoneTracker:", address(milestoneTracker));
        console.log("UniverseManager:", address(universeManager));
        console.log("VelocityManager:", address(velocityManager));
        console.log("CosmicParts:", address(cosmicParts));
        console.log("Staking:", address(staking));

        // Verify deployment
        (
            address riseRacers,
            address mt,
            address um,
            address vm_,
            address cp,
            address st,
            address rc
        ) = registry.getAllContracts();

        require(riseRacers == address(game), "RiseRacers address mismatch");
        require(
            mt == address(milestoneTracker),
            "MilestoneTracker address mismatch"
        );
        require(
            um == address(universeManager),
            "UniverseManager address mismatch"
        );
        require(
            vm_ == address(velocityManager),
            "VelocityManager address mismatch"
        );
        require(cp == address(cosmicParts), "CosmicParts address mismatch");
        require(st == address(staking), "Staking address mismatch");
    }
}
