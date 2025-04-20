// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStaking.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IRiseCrystals.sol";
import "./Registry.sol";

contract Staking is IStaking, Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant STAKING_FEE_PERCENT = 5; // 0.5%
    uint256 public constant SECONDS_PER_HOUR = 3600;
    uint256 public constant LOCKUP_DURATION = 30 days;
    uint256 public constant CRYSTALS_PER_ETH = 1_000_000e18; // 1 Million Rise Crystals (assuming 18 decimals) per ETH

    // State variables
    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public lastDistributionTime;
    Registry public registry;

    // Events
    event Staked(address indexed staker, uint256 amount, uint256 lockEndTime);
    event Unstaked(address indexed staker, uint256 amount);
    event CrystalsClaimed(address indexed staker, uint256 amount);
    event RiseCrystalsTokenSet(address indexed tokenAddress);

    constructor(Registry _registry) Ownable(msg.sender) {
        registry = _registry;
        lastDistributionTime = block.timestamp;
    }

    function stakeETH() external payable override nonReentrant {
        require(msg.value > 0, "Must stake non-zero amount");

        uint256 fee = (msg.value * STAKING_FEE_PERCENT) / 1000;
        uint256 stakeAmount = msg.value - fee;
        uint256 lockEndTime = block.timestamp + LOCKUP_DURATION;

        // Get reference to existing stake
        StakeInfo storage existingStake = stakes[msg.sender];

        // If user is already staking, add to their existing stake
        if (existingStake.amount > 0) {
            // Add new stake amount to existing stake
            existingStake.amount += stakeAmount;
            // Reset lock period
            existingStake.lockEndTime = lockEndTime;
        } else {
            // Create new stake
            stakes[msg.sender] = StakeInfo({
                amount: stakeAmount,
                startTime: block.timestamp,
                claimedCrystals: 0,
                lockEndTime: lockEndTime
            });
        }

        totalStaked += stakeAmount;

        uint256 crystalsToMint = calculateRiseCrystals(msg.value);
        IRiseCrystals(registry.getRiseCrystals()).mint(
            msg.sender,
            crystalsToMint
        );

        payable(owner()).transfer(fee);

        emit Staked(msg.sender, stakeAmount, lockEndTime);
    }

    function calculateRiseCrystals(
        uint256 amount
    ) public pure returns (uint256) {
        return (amount * CRYSTALS_PER_ETH) / 1 ether;
    }

    function unstakeETH() external override nonReentrant {
        StakeInfo storage stake = stakes[msg.sender];
        require(stake.amount > 0, "No stake found");
        require(block.timestamp >= stake.lockEndTime, "Stake is locked");

        uint256 amount = stake.amount;
        totalStaked -= amount;
        delete stakes[msg.sender];

        payable(msg.sender).transfer(amount);
        emit Unstaked(msg.sender, amount);
    }

    function distributePool() external override nonReentrant {
        require(msg.sender == owner(), "Only owner can distribute");
        require(
            block.timestamp >= lastDistributionTime + SECONDS_PER_HOUR,
            "Too soon"
        );

        lastDistributionTime = block.timestamp;
    }

    function getStakeInfo(
        address staker
    ) external view returns (StakeInfo memory) {
        return stakes[staker];
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance - totalStaked;
        require(balance > 0, "No fees to withdraw");
        payable(owner()).transfer(balance);
    }
}
