// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/RiseRacersTest.sol";
import "../src/UniverseManager.sol";
import "../src/VelocityManager.sol";
import "../src/MilestoneTracker.sol";
import "../src/Registry.sol";
import "forge-std/console.sol";

contract UniverseManagerTest is RiseRacersTest {
    function testInitialUniverse() public {
        // Check universe 0
        (
            uint256 id,
            uint256 multiplier,
            string memory badgeName
        ) = universeManager.universes(0);

        assertEq(id, 0);
        assertEq(multiplier, 1);
        assertEq(badgeName, "Novice Racer");
    }

    function testGetCurrentUniverse() public {
        uint256 currentUniverse = universeManager.getCurrentUniverse(
            PLAYER_ONE
        );
        assertEq(currentUniverse, 0); // Should start at universe 0
    }

    function testGetUniverseMultiplier() public {
        uint256 multiplier = universeManager.getUniverseMultiplier(PLAYER_ONE);
        assertEq(multiplier, 1); // Initial multiplier at universe 0
    }

    function testCannotRebirthWithoutLightSpeed() public {
        vm.startPrank(PLAYER_ONE);
        vm.expectRevert("Must reach light speed to rebirth");
        universeManager.rebirth();
        vm.stopPrank();
    }

    function testSuccessfulRebirth() public {
        // Reach light speed
        reachLightSpeed(PLAYER_ONE);

        vm.startPrank(PLAYER_ONE);
        universeManager.rebirth();

        uint256 newUniverse = universeManager.getCurrentUniverse(PLAYER_ONE);
        assertEq(newUniverse, 1);

        // Check new multiplier (1.5x = 15 in integer math)
        uint256 newMultiplier = universeManager.getUniverseMultiplier(
            PLAYER_ONE
        );
        assertEq(newMultiplier, 15);
        vm.stopPrank();
    }

    function testCannotRebirthBeyondMaxUniverse() public {
        reachLightSpeed(PLAYER_ONE);

        // Progress through all universes
        for (uint256 i = 0; i < 5; i++) {
            vm.startPrank(PLAYER_ONE);
            universeManager.rebirth();
            vm.stopPrank();

            // Need to reach light speed again in the new universe
            reachLightSpeed(PLAYER_ONE);
        }

        vm.startPrank(PLAYER_ONE);
        // Try to rebirth in the final universe
        vm.expectRevert("Already at max universe");
        universeManager.rebirth();
        vm.stopPrank();
    }

    function testUniverseMultiplierProgression() public {
        uint256[] memory expectedMultipliers = new uint256[](6);
        expectedMultipliers[0] = 1; // Universe 0 (1x)
        expectedMultipliers[1] = 15; // Universe 1 (1.5x)
        expectedMultipliers[2] = 225; // Universe 2 (2.25x)
        expectedMultipliers[3] = 338; // Universe 3 (3.38x)
        expectedMultipliers[4] = 506; // Universe 4 (5.06x)
        expectedMultipliers[5] = 759; // Universe 5 (7.59x)

        // Check initial multiplier
        assertEq(
            universeManager.getUniverseMultiplier(PLAYER_ONE),
            expectedMultipliers[0]
        );

        reachLightSpeed(PLAYER_ONE);

        for (uint256 i = 0; i < expectedMultipliers.length - 1; i++) {
            // Rebirth to next universe
            vm.startPrank(PLAYER_ONE);
            universeManager.rebirth();
            vm.stopPrank();

            // Check multiplier
            assertEq(
                universeManager.getUniverseMultiplier(PLAYER_ONE),
                expectedMultipliers[i + 1]
            );

            // Need to reach light speed in the new universe
            reachLightSpeed(PLAYER_ONE);
        }
    }

    function testVelocityResetOnRebirth() public {
        reachLightSpeed(PLAYER_ONE);

        vm.startPrank(PLAYER_ONE);
        universeManager.rebirth();

        uint256 newVelocity = velocityManager.getCurrentVelocity(PLAYER_ONE);
        assertEq(newVelocity, 0);
        vm.stopPrank();
    }

    function testVelocityManagerIsImmutable() public {
        assertEq(
            address(universeManager.velocityManager()),
            address(velocityManager)
        );
    }
}
