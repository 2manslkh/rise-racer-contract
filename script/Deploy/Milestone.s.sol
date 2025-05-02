// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../../src/RiseRacers.sol";
import "../../src/MilestoneTracker.sol";
import "../../src/UniverseManager.sol";
import "../../src/CosmicParts.sol";
import "../../src/Staking.sol";
import "../../src/VelocityManager.sol";
import "../../src/Registry.sol";
import "../../src/RiseCrystals.sol";

contract DeployScript is Script {
    function run() external {
        // Get deployment private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        Registry registry = Registry(
            0x4c345Df0C083f502BDA09768D8f0B882f16f4711
        );
        // If deploying locally, use a default private key
        if (block.chainid == 31337) {
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy contracts that don't need registry first
        MilestoneTracker milestoneTracker = new MilestoneTracker(registry);

        registry.updateContract(
            registry.MILESTONE_TRACKER(),
            address(milestoneTracker)
        );
    }
}
