// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers/RiseRacersTest.sol";

contract RiseRacersGameTest is RiseRacersTest {
    function testInitializePlayer() public {
        vm.startPrank(PLAYER_ONE);

        RiseRacers.PlayerInfo memory info = game.getPlayerInfo(PLAYER_ONE);
        assertEq(info.velocity, 0);
        assertEq(info.currentUniverse, 0);
        assertEq(info.totalClicks, 0);
        assertEq(info.isStaking, false);
        vm.stopPrank();
    }

    function testClick() public {
        vm.startPrank(PLAYER_ONE);

        game.click();

        RiseRacers.PlayerInfo memory info = game.getPlayerInfo(PLAYER_ONE);
        assertTrue(info.velocity > 0);
        assertEq(info.totalClicks, 1);
        vm.stopPrank();
    }

    function testClickPowerCalculation() public {
        vm.startPrank(PLAYER_ONE);

        // Base click power should be 1
        uint256 basePower = game.getClickPower(PLAYER_ONE);
        assertEq(basePower, 1);

        // Mint and equip a common engine part
        equipPart(
            PLAYER_ONE,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Common
        );

        // Power should increase by ENGINE_BASE_BOOST (10)
        uint256 boostedPower = game.getClickPower(PLAYER_ONE);
        assertEq(boostedPower, 11);
        vm.stopPrank();
    }

    function testPause() public {
        vm.prank(OWNER);
        game.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);
        game.click();

        vm.prank(OWNER);
        game.unpause();

        // Should work after unpause
        game.click();
    }
}
