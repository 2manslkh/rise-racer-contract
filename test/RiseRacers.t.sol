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
