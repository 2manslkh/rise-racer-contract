// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/RiseRacersTest.sol";
import "../src/MilestoneTracker.sol";
import "../src/VelocityManager.sol";
import "../src/Registry.sol";
import "forge-std/console.sol";

contract MilestoneTrackerTest is RiseRacersTest {
    function setUp() public override {
        super.setUp();
    }

    function testInitialMilestones() public {
        // Check first milestone (Sound Barrier)
        (
            uint256 id,
            uint256 speedRequirement,
            string memory name,
            string memory description,
            bool achieved
        ) = milestoneTracker.milestones(0);

        assertEq(id, 0);
        assertEq(speedRequirement, 343);
        assertEq(name, "Sound Barrier");
        assertEq(description, "Break the sound barrier");
        assertEq(achieved, false);

        // Check last milestone (Light Speed)
        (id, speedRequirement, name, description, achieved) = milestoneTracker
            .milestones(8);
        assertEq(id, 8);
        assertEq(speedRequirement, 299792458);
        assertEq(name, "Light Speed");
        assertEq(description, "Achieve the speed of light!");
        assertEq(achieved, false);
    }

    function testGetCurrentMilestone() public {
        uint256 currentMilestone = milestoneTracker.getCurrentMilestone(
            PLAYER_ONE
        );
        assertEq(currentMilestone, 0);
    }

    function testCheckMilestoneAchievement() public {
        // Set up VelocityManager with enough speed to reach first milestone
        addVelocity(PLAYER_ONE, 344); // Just above sound barrier

        // Call through RiseRacers since it's the only one that can check milestones
        vm.startPrank(address(game));
        velocityManager.checkSpeedMilestone(PLAYER_ONE);
        vm.stopPrank();

        // Verify milestone was achieved
        (uint256 currentMilestone, ) = milestoneTracker
            .getCurrentMilestoneWithSpeed(PLAYER_ONE);
        assertEq(currentMilestone, 1); // Should be at milestone 1 (second milestone)
        assertTrue(milestoneTracker.achievedMilestones(PLAYER_ONE, 0)); // First milestone (ID 0) should be achieved
    }

    function testClaimMilestoneNFT() public {
        // Achieve first milestone (ID 0)
        addVelocity(PLAYER_ONE, 344);
        vm.startPrank(address(game));
        velocityManager.checkSpeedMilestone(PLAYER_ONE);
        vm.stopPrank();

        // Claim milestone 0
        vm.startPrank(PLAYER_ONE);
        milestoneTracker.claimMilestoneNFT(0);
        assertEq(milestoneTracker.ownerOf(0), PLAYER_ONE);
        vm.stopPrank();
    }

    function testCannotClaimUnachievedMilestone() public {
        vm.startPrank(PLAYER_ONE);
        vm.expectRevert("Milestone not achieved");
        milestoneTracker.claimMilestoneNFT(0);
        vm.stopPrank();
    }

    function testCannotClaimSameMilestoneTwice() public {
        // Check initial velocity
        uint256 initialVelocity = velocityManager.getCurrentVelocity(
            PLAYER_ONE
        );
        console.log("Initial velocity:", initialVelocity);

        // First achieve and claim the milestone
        addVelocity(PLAYER_ONE, 344);
        uint256 velocityAfterAdd = velocityManager.getCurrentVelocity(
            PLAYER_ONE
        );
        console.log("Velocity after adding 344 m/s:", velocityAfterAdd);

        vm.startPrank(address(game));
        velocityManager.checkSpeedMilestone(PLAYER_ONE);
        vm.stopPrank();

        uint256 velocityAfterCheck = velocityManager.getCurrentVelocity(
            PLAYER_ONE
        );
        console.log("Velocity after milestone check:", velocityAfterCheck);

        vm.startPrank(PLAYER_ONE);
        milestoneTracker.claimMilestoneNFT(0); // Claim milestone 0

        uint256 velocityAfterFirstClaim = velocityManager.getCurrentVelocity(
            PLAYER_ONE
        );
        console.log("Velocity after first NFT claim:", velocityAfterFirstClaim);

        vm.expectRevert("Already claimed");
        milestoneTracker.claimMilestoneNFT(0); // Try to claim again

        uint256 finalVelocity = velocityManager.getCurrentVelocity(PLAYER_ONE);
        console.log("Final velocity:", finalVelocity);
        vm.stopPrank();
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

        for (uint256 i = 0; i < speeds.length; i++) {
            addVelocity(PLAYER_ONE, speeds[i]);
            vm.startPrank(address(game));
            velocityManager.checkSpeedMilestone(PLAYER_ONE);
            vm.stopPrank();
            assertEq(milestoneTracker.getCurrentMilestone(PLAYER_ONE), i + 1);
            assertTrue(milestoneTracker.achievedMilestones(PLAYER_ONE, i));
        }
    }
}
