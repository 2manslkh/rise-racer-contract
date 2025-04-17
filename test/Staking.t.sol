// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Staking.sol";

contract StakingTest is Test {
    Staking public staking;
    address public player1 = address(0x100);
    address public player2 = address(0x200);
    address public owner;

    function setUp() public {
        vm.startPrank(address(this));
        staking = new Staking();
        owner = address(this);
        vm.stopPrank();

        vm.deal(player1, 10 ether);
        vm.deal(player2, 10 ether);
        vm.deal(owner, 1 ether);
    }

    function testStakeETH() public {
        vm.startPrank(player1);
        uint256 stakeAmount = 1 ether;
        staking.stakeETH{value: stakeAmount}();

        IStaking.StakeInfo memory info = staking.getStakeInfo(player1);
        // Account for 0.5% fee
        uint256 expectedStakeAmount = (stakeAmount * 995) / 1000;
        assertEq(info.amount, expectedStakeAmount);
        assertEq(info.claimedCrystals, 0);
        assertTrue(info.startTime > 0);
        vm.stopPrank();
    }

    function testCannotStakeBelowMinimum() public {
        vm.startPrank(player1);
        vm.expectRevert("Below minimum stake");
        staking.stakeETH{value: 0.009 ether}();
        vm.stopPrank();
    }

    function testCannotStakeAboveMaximum() public {
        vm.startPrank(player1);
        vm.expectRevert("Above maximum stake");
        staking.stakeETH{value: 6 ether}();
        vm.stopPrank();
    }

    function testCannotStakeWhileStaking() public {
        vm.startPrank(player1);
        staking.stakeETH{value: 1 ether}();

        vm.expectRevert("Already staking");
        staking.stakeETH{value: 1 ether}();
        vm.stopPrank();
    }

    function testUnstakeETH() public {
        // First stake
        vm.startPrank(player1);
        uint256 stakeAmount = 1 ether;
        staking.stakeETH{value: stakeAmount}();
        uint256 expectedStakeAmount = (stakeAmount * 995) / 1000;

        // Add this to ensure contract has enough balance
        vm.deal(address(staking), expectedStakeAmount);

        // Record balance before unstaking
        uint256 balanceBefore = player1.balance;

        // Unstake
        staking.unstakeETH();

        // Check balance after unstaking
        uint256 balanceAfter = player1.balance;
        assertEq(balanceAfter - balanceBefore, expectedStakeAmount);

        // Check stake info is cleared
        IStaking.StakeInfo memory info = staking.getStakeInfo(player1);
        assertEq(info.amount, 0);
        vm.stopPrank();
    }

    function testCannotUnstakeWithoutStake() public {
        vm.startPrank(player1);
        vm.expectRevert("No stake found");
        staking.unstakeETH();
        vm.stopPrank();
    }

    function testCalculateRiseCrystals() public {
        // Stake from both players
        vm.prank(player1);
        staking.stakeETH{value: 1 ether}();
        vm.prank(player2);
        staking.stakeETH{value: 1 ether}();

        // Warp time forward by 1 hour
        vm.warp(block.timestamp + 3600);

        // Calculate rewards
        uint256 player1Crystals = staking.calculateRiseCrystals(player1);
        uint256 player2Crystals = staking.calculateRiseCrystals(player2);

        // Both players should get approximately 50k crystals (half of CRYSTALS_PER_HOUR)
        assertApproxEqRel(player1Crystals, 50000, 0.01e18); // 1% tolerance
        assertApproxEqRel(player2Crystals, 50000, 0.01e18);
    }

    function testDistributePool() public {
        // Set up initial state
        vm.prank(player1);
        staking.stakeETH{value: 1 ether}();

        // First distribution should work after 1 hour
        vm.warp(block.timestamp + 3600);
        vm.prank(owner);
        staking.distributePool();

        // Cannot distribute too soon
        vm.expectRevert("Too soon");
        vm.prank(owner);
        staking.distributePool();

        // Can distribute after an hour
        vm.warp(block.timestamp + 3600);
        vm.prank(owner);
        staking.distributePool();
    }

    function testWithdrawFees() public {
        // Directly send ETH to contract (not through staking)
        vm.deal(address(staking), 1 ether);

        // Calculate expected fee (now using full 1 ether)
        uint256 expectedFee = 1 ether;

        // Record owner balance before withdrawal
        uint256 balanceBefore = owner.balance;

        // Withdraw fees
        vm.prank(owner);
        staking.withdrawFees();

        // Check owner received fees
        uint256 balanceAfter = owner.balance;
        assertEq(balanceAfter - balanceBefore, expectedFee);
    }

    function testCannotWithdrawFeesAsNonOwner() public {
        // Generate fees through direct transfer
        vm.deal(address(staking), 1 ether);

        vm.startPrank(player1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                player1
            )
        );
        staking.withdrawFees();
        vm.stopPrank();
    }

    function testCannotWithdrawWithNoFees() public {
        vm.startPrank(owner);
        vm.expectRevert("No fees to withdraw");
        staking.withdrawFees();
        vm.stopPrank();
    }

    receive() external payable {}
}
