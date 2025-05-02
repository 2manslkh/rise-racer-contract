// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {RiseRacersTest} from "./helpers/RiseRacersTest.sol";
import {MilestoneTracker} from "../src/MilestoneTracker.sol";
import {VelocityManager} from "../src/VelocityManager.sol";
import {Registry} from "../src/Registry.sol";
import {IRiseRacers} from "../src/interfaces/IRiseRacers.sol";
import {IMilestones} from "../src/interfaces/IMilestones.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract MilestoneTrackerTest is RiseRacersTest {
    // Define deployer address (assuming it's owner/authorized for VM)
    address internal deployer = address(0x1);

    // Helper function to reset velocity (requires authorization)
    function _resetVelocity(address player) internal {
        // Assuming velocityManager is set up in RiseRacersTest.setUp()
        // Assuming deployer (or owner address from parent setup) is authorized
        address owner = deployer; // Use deployer defined in this contract
        vm.startPrank(address(universeManager));
        velocityManager.resetVelocity(player);
        vm.stopPrank();
    }

    // Helper function to set velocity (requires authorization via reset/add)
    function _setVelocity(address player, uint256 speed) internal {
        _resetVelocity(player); // Reset first
        // Use addVelocity inherited from RiseRacersTest
        addVelocity(player, speed);
    }

    function setUp() public override {
        super.setUp();
    }

    function testInitialMilestones() public {
        // Check first milestone (Ignition, ID 1) using getMilestoneDetails
        IMilestones.Milestone memory milestone1 = milestoneTracker
            .getMilestoneDetails(1);
        assertEq(milestone1.id, 1, "Test Initial: ID 1");
        assertEq(milestone1.speedRequirement, 50, "Test Initial: Speed 1");
        assertEq(milestone1.name, "Ignition", "Test Initial: Name 1");
        assertEq(
            milestone1.description,
            "Kick off your journey with a modest burst of speed.",
            "Test Initial: Desc 1"
        );

        // Check last milestone (Light Speed Achievement, ID 13) using getMilestoneDetails
        IMilestones.Milestone memory milestone13 = milestoneTracker
            .getMilestoneDetails(13);
        assertEq(milestone13.id, 13, "Test Initial: ID 13");
        assertEq(
            milestone13.speedRequirement,
            299792458,
            "Test Initial: Speed 13"
        );
        assertEq(
            milestone13.name,
            "Light Speed Achievement",
            "Test Initial: Name 13"
        );
        assertEq(
            milestone13.description,
            "Achieve the legendary milestone-breaking the ultimate speed barrier.",
            "Test Initial: Desc 13"
        );
    }

    function testGetCurrentMilestone_Initial() public {
        uint8 currentMilestone = milestoneTracker.getCurrentMilestone(
            PLAYER_ONE
        );
        assertEq(currentMilestone, 0, "Test Current Initial: Should be 0");
    }

    function testCheckMilestoneAchievement() public {
        // Add speed for Milestone 1 (Ignition)
        addVelocity(PLAYER_ONE, 50);

        (uint8 currentMilestone, uint256 currentSpeed) = milestoneTracker
            .getCurrentMilestoneWithSpeed(PLAYER_ONE);
        // Use console.log explicitly
        console.log(
            "Speed:",
            currentSpeed,
            "Expected Milestone: 1, Got:",
            currentMilestone
        );
        assertEq(currentMilestone, 1, "Test Check: Milestone 1 (50 m/s)");

        // Reset and test a higher milestone
        _resetVelocity(PLAYER_ONE); // Use helper
        addVelocity(PLAYER_ONE, 343); // Speed for Milestone 2 (Sound Barrier)

        (currentMilestone, currentSpeed) = milestoneTracker
            .getCurrentMilestoneWithSpeed(PLAYER_ONE);
        // Use console.log explicitly
        console.log(
            "Speed:",
            currentSpeed,
            "Expected Milestone: 2, Got:",
            currentMilestone
        );
        assertEq(currentMilestone, 2, "Test Check: Milestone 2 (343 m/s)");

        // Reset and test just below a threshold
        _resetVelocity(PLAYER_ONE); // Use helper
        addVelocity(PLAYER_ONE, 11199); // Speed just below Milestone 5 (Escape Velocity)
        (currentMilestone, currentSpeed) = milestoneTracker
            .getCurrentMilestoneWithSpeed(PLAYER_ONE);
        // Use console.log explicitly
        console.log(
            "Speed:",
            currentSpeed,
            "Expected Milestone: 4, Got:",
            currentMilestone
        );
        assertEq(currentMilestone, 4, "Test Check: Below Milestone 5"); // Should be Milestone 4
    }

    function testProgressiveMilestones() public {
        // Test speeds for each of the 13 milestones
        uint256[] memory speeds = new uint256[](13);
        speeds[0] = 50; // 1. Ignition
        speeds[1] = 343; // 2. Sound Barrier
        speeds[2] = 1000; // 3. Suborbital Flight
        speeds[3] = 7800; // 4. Orbital Velocity
        speeds[4] = 11200; // 5. Escape Velocity
        speeds[5] = 299792; // 6. Initial Cosmic Leap (~0.1% c)
        speeds[6] = 2997925; // 7. Rapid Acceleration (~1% c)
        speeds[7] = 29979246; // 8. Hyper Drive (~10% c)
        speeds[8] = 74948115; // 9. Cosmic Sprint (~25% c)
        speeds[9] = 149896229; // 10. Superluminal Approach (~50% c)
        speeds[10] = 269813212; // 11. Near Light-Speed (~90% c)
        speeds[11] = 296794533; // 12. Final Thrust (~99% c)
        speeds[12] = 299792458; // 13. Light Speed Achievement

        for (uint256 i = 0; i < speeds.length; i++) {
            // Use helper function to set velocity
            _setVelocity(PLAYER_ONE, speeds[i]);

            uint8 achievedMilestone = milestoneTracker.getCurrentMilestone(
                PLAYER_ONE
            );
            uint256 expectedMilestone = i + 1; // Milestones are 1-indexed

            // Use Strings.toString() for dynamic error message
            assertEq(
                achievedMilestone,
                expectedMilestone,
                string(
                    abi.encodePacked(
                        "Test Progressive: Milestone ",
                        Strings.toString(expectedMilestone)
                    )
                )
            );
        }
    }
}
