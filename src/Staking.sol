// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStaking.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IRiseCrystals.sol";

contract Staking is IStaking, Ownable, ReentrancyGuard {
    // Constants
    uint256 public constant MIN_STAKE = 0.01 ether;
    uint256 public constant MAX_STAKE = 5 ether;
    uint256 public constant STAKING_FEE_PERCENT = 5; // 0.5%
    uint256 public constant CRYSTALS_PER_HOUR = 100000; // 100k Rise Crystals per hour
    uint256 public constant SECONDS_PER_HOUR = 3600;
    uint256 public constant LOCKUP_DURATION = 30 days;
    uint256 public constant CRYSTALS_PER_ETH = 1_000_000e18; // 1 Million Rise Crystals (assuming 18 decimals) per ETH

    // State variables
    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public lastDistributionTime;
    IRiseCrystals public riseCrystalsToken;

    // Events
    event Staked(address indexed staker, uint256 amount, uint256 lockEndTime);
    event Unstaked(address indexed staker, uint256 amount);
    event CrystalsClaimed(address indexed staker, uint256 amount);
    event RiseCrystalsTokenSet(address indexed tokenAddress);

    constructor() Ownable(msg.sender) {
        lastDistributionTime = block.timestamp;
    }

    function setRiseCrystalsTokenAddress(
        address _tokenAddress
    ) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid address");
        riseCrystalsToken = IRiseCrystals(_tokenAddress);
        emit RiseCrystalsTokenSet(_tokenAddress);
    }

    function stakeETH() external payable override nonReentrant {
        require(
            address(riseCrystalsToken) != address(0),
            "RiseCrystals token not set"
        );
        require(msg.value >= MIN_STAKE, "Below minimum stake");
        require(msg.value <= MAX_STAKE, "Above maximum stake");
        require(stakes[msg.sender].amount == 0, "Already staking");

        uint256 fee = (msg.value * STAKING_FEE_PERCENT) / 1000;
        uint256 stakeAmount = msg.value - fee;
        uint256 lockEndTime = block.timestamp + LOCKUP_DURATION;

        stakes[msg.sender] = StakeInfo({
            amount: stakeAmount,
            startTime: block.timestamp,
            claimedCrystals: 0,
            lockEndTime: lockEndTime
        });

        totalStaked += stakeAmount;

        uint256 crystalsToMint = (msg.value * CRYSTALS_PER_ETH) / 1 ether;
        riseCrystalsToken.mint(msg.sender, crystalsToMint);

        payable(owner()).transfer(fee);

        emit Staked(msg.sender, stakeAmount, lockEndTime);
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

    function calculateRiseCrystals(
        address staker
    ) public view override returns (uint256) {
        StakeInfo storage stake = stakes[staker];
        if (stake.amount == 0) return 0;

        uint256 hoursSinceLastClaim = (block.timestamp - stake.startTime) /
            SECONDS_PER_HOUR;
        if (hoursSinceLastClaim == 0) return 0;

        uint256 stakerShare = (stake.amount * 1e18) / totalStaked;
        uint256 crystals = (CRYSTALS_PER_HOUR *
            hoursSinceLastClaim *
            stakerShare) / 1e18;

        return crystals - stake.claimedCrystals;
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
