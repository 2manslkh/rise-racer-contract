// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UD60x18, ud, powu, mul, uUNIT} from "@prb/math/UD60x18.sol";
import {convert} from "@prb/math/ud60x18/Conversions.sol";

contract Curves {
    // Use 1e18 for scaling calculations with PRBMath
    uint256 public constant DECIMAL_SCALE = 1 ether;

    // --- Wheel Constants ---
    uint256 public constant WHEEL_BASE_COST = 20 ether; // Base cost scaled
    uint256 public constant WHEEL_COST_GROWTH_FACTOR = 1180000000000000000; // 1.18x per level
    uint256 public constant WHEEL_BASE_VELOCITY = 2 ether; // Base velocity scaled
    uint256 public constant WHEEL_VELOCITY_GROWTH_FACTOR = 1180000000000000000; // 1.10x velocity per level (Increased from 1.08)

    // --- Engine Constants ---
    uint256 public constant ENGINE_BASE_COST = 100 ether; // Base cost scaled
    uint256 public constant ENGINE_COST_GROWTH_FACTOR = 1250000000000000000; // 1.25x per level
    uint256 public constant ENGINE_BASE_VELOCITY = 5 ether; // Base velocity scaled
    uint256 public constant ENGINE_VELOCITY_GROWTH_FACTOR = 1350000000000000000; // 1.15x velocity per level (Increased from 1.12)

    // --- Chassis Constants ---
    uint256 public constant CHASSIS_BASE_COST = 10 ether; // Base cost scaled
    uint256 public constant CHASSIS_COST_GROWTH_FACTOR = 1120000000000000000; // 1.12x per level
    uint256 public constant CHASSIS_BASE_VELOCITY = 1 ether; // Base velocity scaled
    uint256 public constant CHASSIS_VELOCITY_GROWTH_FACTOR =
        1080000000000000000; // 1.08x velocity per level (Increased from 1.05)

    // --- Turbo Constants ---
    uint256 public constant TURBO_BASE_COST = 500 ether; // Base cost scaled
    uint256 public constant TURBO_COST_GROWTH_FACTOR = 1350000000000000000; // 1.35x per level
    uint256 public constant TURBO_BASE_VELOCITY = 3 ether; // Base velocity scaled
    uint256 public constant TURBO_VELOCITY_GROWTH_FACTOR = 1100000000000000000; // 1.22x velocity per level (Increased from 1.18)

    // === Cost Calculation Functions ===

    function getWheelCost(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be >= 1");
        if (level == 1) {
            return WHEEL_BASE_COST; // Return scaled base cost as integer
        }
        UD60x18 base = ud(WHEEL_BASE_COST);
        UD60x18 factor = ud(WHEEL_COST_GROWTH_FACTOR);
        UD60x18 cost = mul(base, powu(factor, level - 1));
        return cost.unwrap(); // Return integer value
    }

    function getEngineCost(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be >= 1");
        if (level == 1) {
            return ENGINE_BASE_COST;
        }
        UD60x18 base = ud(ENGINE_BASE_COST);
        UD60x18 factor = ud(ENGINE_COST_GROWTH_FACTOR);
        UD60x18 cost = mul(base, powu(factor, level - 1));
        return cost.unwrap();
    }

    function getChassisCost(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be >= 1");
        if (level == 1) {
            return CHASSIS_BASE_COST;
        }
        UD60x18 base = ud(CHASSIS_BASE_COST);
        UD60x18 factor = ud(CHASSIS_COST_GROWTH_FACTOR);
        UD60x18 cost = mul(base, powu(factor, level - 1));
        return cost.unwrap();
    }

    function getTurboCost(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be >= 1");
        if (level == 1) {
            return TURBO_BASE_COST;
        }
        UD60x18 base = ud(TURBO_BASE_COST);
        UD60x18 factor = ud(TURBO_COST_GROWTH_FACTOR);
        UD60x18 cost = mul(base, powu(factor, level - 1));
        return cost.unwrap();
    }

    // === Velocity Calculation Functions (Now Exponential * Level) ===

    function getWheelVelocity(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be >= 1");
        UD60x18 base = ud(WHEEL_BASE_VELOCITY);
        if (level == 1) {
            // For level 1, factor^0 = 1, level = 1. Result is just base.
            return base.unwrap() / uUNIT;
        }
        UD60x18 factor = ud(WHEEL_VELOCITY_GROWTH_FACTOR);
        UD60x18 expVelocity = mul(base, powu(factor, level - 1));
        // Multiply by level
        UD60x18 finalVelocity = mul(expVelocity, convert(level));
        return finalVelocity.unwrap() / uUNIT; // Return integer value
    }

    function getEngineVelocity(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be >= 1");
        UD60x18 base = ud(ENGINE_BASE_VELOCITY);
        if (level == 1) {
            return base.unwrap() / uUNIT;
        }
        UD60x18 factor = ud(ENGINE_VELOCITY_GROWTH_FACTOR);
        UD60x18 expVelocity = mul(base, powu(factor, level - 1));
        // Multiply by level
        UD60x18 finalVelocity = mul(expVelocity, convert(level));
        return finalVelocity.unwrap() / uUNIT;
    }

    function getChassisVelocity(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be >= 1");
        UD60x18 base = ud(CHASSIS_BASE_VELOCITY);
        if (level == 1) {
            return base.unwrap() / uUNIT;
        }
        UD60x18 factor = ud(CHASSIS_VELOCITY_GROWTH_FACTOR);
        UD60x18 expVelocity = mul(base, powu(factor, level - 1));
        // Multiply by level
        UD60x18 finalVelocity = mul(expVelocity, convert(level));
        return finalVelocity.unwrap() / uUNIT;
    }

    function getTurboVelocity(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be >= 1");
        UD60x18 base = ud(TURBO_BASE_VELOCITY);
        if (level == 1) {
            return base.unwrap() / uUNIT;
        }
        UD60x18 factor = ud(TURBO_VELOCITY_GROWTH_FACTOR);
        UD60x18 expVelocity = mul(base, powu(factor, level - 1));
        // Multiply by level
        UD60x18 finalVelocity = mul(expVelocity, convert(level));
        return finalVelocity.unwrap() / uUNIT;
    }
}
