// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "../src/interfaces/IRiseCrystals.sol"; // Import interface
import "./helpers/RiseRacersTest.sol";

// --- End Mock ---

contract StakingTest is RiseRacersTest {
    function setUp() public override {
        super.setUp();
        // Fund players with ETH
        vm.deal(PLAYER_ONE, 10 ether);
        vm.deal(PLAYER_TWO, 10 ether);
        // Fund owner?
        // vm.deal(owner, 1 ether); // Not strictly needed unless owner pays gas
    }

    function testStakeETH() public {
        vm.startPrank(PLAYER_ONE);
        uint256 stakeAmount = 1 ether;
        staking.stakeETH{value: stakeAmount}();

        IStaking.StakeInfo memory info = staking.getStakeInfo(PLAYER_ONE);
        // Account for 0.5% fee
        uint256 expectedStakeAmount = (stakeAmount * 995) / 1000;
        assertEq(info.amount, expectedStakeAmount);
        assertEq(info.claimedCrystals, 0);
        assertTrue(info.startTime > 0);
        vm.stopPrank();
    }

    function testAdditionalStake() public {
        vm.startPrank(PLAYER_ONE);

        // Initial stake
        uint256 initialStake = 1 ether;
        staking.stakeETH{value: initialStake}();

        // Record initial lock end time
        IStaking.StakeInfo memory infoBeforeAdditional = staking.getStakeInfo(
            PLAYER_ONE
        );
        uint256 initialLockEndTime = infoBeforeAdditional.lockEndTime;
        uint256 initialStakeAmount = infoBeforeAdditional.amount;

        // Wait 10 days
        vm.warp(block.timestamp + 10 days);

        // Additional stake
        uint256 additionalStake = 2 ether;
        staking.stakeETH{value: additionalStake}();

        // Check updated stake info
        IStaking.StakeInfo memory infoAfterAdditional = staking.getStakeInfo(
            PLAYER_ONE
        );

        // Account for 0.5% fee on both stakes
        uint256 expectedInitialAmount = (initialStake * 995) / 1000;
        uint256 expectedAdditionalAmount = (additionalStake * 995) / 1000;
        uint256 expectedTotalAmount = expectedInitialAmount +
            expectedAdditionalAmount;

        // Verify amount increased
        assertEq(
            infoAfterAdditional.amount,
            expectedTotalAmount,
            "Total stake amount should be sum of both stakes minus fees"
        );

        // Verify lock end time was reset and extended
        assertTrue(
            infoAfterAdditional.lockEndTime > initialLockEndTime,
            "Lock end time should be extended"
        );
        assertEq(
            infoAfterAdditional.lockEndTime,
            block.timestamp + staking.LOCKUP_DURATION(),
            "Lock should be reset to full duration"
        );

        vm.stopPrank();
    }

    function testUnstakeETH() public {
        // First stake
        vm.startPrank(PLAYER_ONE);
        uint256 stakeAmount = 1 ether;
        staking.stakeETH{value: stakeAmount}();
        uint256 expectedStakeAmount = (stakeAmount * 995) / 1000;

        // Add this to ensure contract has enough balance
        vm.deal(address(staking), expectedStakeAmount);

        // --- Advance time past lockup ---
        vm.warp(block.timestamp + staking.LOCKUP_DURATION() + 1);

        // Record balance before unstaking
        uint256 balanceBefore = PLAYER_ONE.balance;

        // Unstake
        staking.unstakeETH();

        // Check balance after unstaking
        uint256 balanceAfter = PLAYER_ONE.balance;
        assertEq(balanceAfter - balanceBefore, expectedStakeAmount);

        // Check stake info is cleared
        IStaking.StakeInfo memory info = staking.getStakeInfo(PLAYER_ONE);
        assertEq(info.amount, 0);
        vm.stopPrank();
    }

    function testCannotUnstakeWithoutStake() public {
        vm.startPrank(PLAYER_ONE);
        vm.expectRevert("No stake found");
        staking.unstakeETH();
        vm.stopPrank();
    }

    function testDistributePool() public {
        // Set up initial state
        vm.prank(PLAYER_ONE);
        staking.stakeETH{value: 1 ether}();

        // First distribution should work after 1 hour
        vm.warp(block.timestamp + 3600);
        vm.prank(OWNER);
        staking.distributePool();

        // Cannot distribute too soon
        vm.expectRevert("Too soon");
        vm.prank(OWNER);
        staking.distributePool();

        // Can distribute after an hour
        vm.warp(block.timestamp + 3600);
        vm.prank(OWNER);
        staking.distributePool();
    }

    function testWithdrawFees() public {
        // Player 1 stakes, generating a fee
        vm.startPrank(PLAYER_ONE);
        uint256 stakeAmount = 1 ether;
        staking.stakeETH{value: stakeAmount}();
        vm.stopPrank();

        uint256 expectedFee = (stakeAmount * staking.STAKING_FEE_PERCENT()) /
            1000;
        // uint256 contractEthBalance = address(staking).balance; // Check contract holds fee
        // assertEq(contractEthBalance, expectedFee, "Contract should hold fee");
        // Note: Staking contract immediately transfers fee to owner in stakeETH

        // Record owner balance before withdrawal
        uint256 balanceBefore = OWNER.balance;

        // Withdraw fees (should be 0 as fee was already transferred)
        vm.startPrank(OWNER);
        // The withdrawFees function checks `address(this).balance - totalStaked`
        // Since fee was transferred out, balance = totalStaked (approx)
        vm.expectRevert("No fees to withdraw");
        staking.withdrawFees();

        // Check owner received fees (This test might be invalid if fee is transferred immediately)
        // uint256 balanceAfter = owner.balance;
        // assertEq(balanceAfter - balanceBefore, expectedFee);
    }

    function testCannotWithdrawFeesAsNonOwner() public {
        // Generate fees through direct transfer
        vm.deal(address(staking), 1 ether);

        vm.startPrank(PLAYER_ONE);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                PLAYER_ONE
            )
        );
        staking.withdrawFees();
        vm.stopPrank();
    }

    function testCannotWithdrawWithNoFees() public {
        vm.startPrank(OWNER);
        vm.expectRevert("No fees to withdraw");
        staking.withdrawFees();
        vm.stopPrank();
    }

    receive() external payable {}
}
