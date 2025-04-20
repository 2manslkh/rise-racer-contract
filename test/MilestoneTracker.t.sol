// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/RiseRacersTest.sol";
import "../src/MilestoneTracker.sol";
import "../src/VelocityManager.sol";
import "../src/Registry.sol";
import "forge-std/console.sol";
import {IRiseRacers} from "../src/interfaces/IRiseRacers.sol";

contract MilestoneTrackerTest is RiseRacersTest {
    function setUp() public override {
        super.setUp();
    }

    function testInitialMilestones() public {
        // Check first milestone (Sound Barrier)
        (
            uint8 id,
            uint256 speedRequirement,
            string memory name,
            string memory description
        ) = milestoneTracker.milestones(0);

        assertEq(id, 0);
        assertEq(speedRequirement, 343);
        assertEq(name, "Sound Barrier");
        assertEq(description, "Break the sound barrier");

        // Check last milestone (Light Speed)
        (id, speedRequirement, name, description) = milestoneTracker.milestones(
            8
        );
        assertEq(id, 8);
        assertEq(speedRequirement, 299792458);
        assertEq(name, "Light Speed");
        assertEq(description, "Achieve the speed of light!");
    }

    function testGetCurrentMilestone() public {
        uint8 currentMilestone = milestoneTracker.getCurrentMilestone(
            PLAYER_ONE
        );
        assertEq(currentMilestone, 0);
    }

    function testCheckMilestoneAchievement() public {
        // Set up VelocityManager with enough speed to reach first milestone
        addVelocity(PLAYER_ONE, 344); // Just above sound barrier

        // Call through RiseRacers since it's the only one that can check milestones
        vm.startPrank(PLAYER_ONE);
        game.click(); // This will check milestone achievement internally
        vm.stopPrank();

        // Verify milestone was achieved
        (uint8 currentMilestone, ) = milestoneTracker
            .getCurrentMilestoneWithSpeed(PLAYER_ONE);
        assertEq(currentMilestone, 0); // Should correctly identify milestone 0 (Sound Barrier)

        // Test a higher milestone
        addVelocity(PLAYER_ONE, 11500); // Above Escape Velocity (11200)
        vm.startPrank(PLAYER_ONE);
        game.click();
        vm.stopPrank();

        (currentMilestone, ) = milestoneTracker.getCurrentMilestoneWithSpeed(
            PLAYER_ONE
        );
        assertEq(currentMilestone, 1); // Should correctly identify milestone 1 (Escape Velocity)
    }

    function testProgressiveMilestones() public {
        // Test each milestone in sequence
        uint256[] memory speeds = new uint256[](9);
        speeds[0] = 343; // Sound Barrier
        speeds[1] = 11200; // Escape Velocity
        speeds[2] = 2997925; // 1% Light Speed
        speeds[3] = 29979246; // 10% Light Speed
        speeds[4] = 149896229; // 50% Light Speed
        speeds[5] = 269813212; // 90% Light Speed
        speeds[6] = 296794533; // 99% Light Speed
        speeds[7] = 299762479; // 99.99% Light Speed
        speeds[8] = 299792458; // Light Speed

        // With the fixed _calculateMilestone, test that each speed threshold
        // returns the correct milestone index
        for (uint256 i = 0; i < speeds.length; i++) {
            // Reset velocity
            vm.startPrank(registry.getUniverseManager());
            velocityManager.resetVelocity(PLAYER_ONE);
            vm.stopPrank();

            // Set speed slightly above the threshold
            addVelocity(PLAYER_ONE, speeds[i] + 1);

            // Click to update game state
            vm.startPrank(PLAYER_ONE);
            game.click();
            vm.stopPrank();

            // Now the implementation is fixed, we expect the correct milestone index
            assertEq(
                uint256(milestoneTracker.getCurrentMilestone(PLAYER_ONE)),
                i
            );

            // Get the player data from rise racers
            IRiseRacers.PlayerInfo memory playerInfo = game.getPlayerInfo(
                PLAYER_ONE
            );

            // Verify the speed is correctly set
            uint256 currentSpeed = velocityManager.getCurrentVelocity(
                PLAYER_ONE
            );
            assertTrue(
                currentSpeed > speeds[i],
                "Speed should be above the milestone requirement"
            );
        }
    }
}
