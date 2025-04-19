// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UD60x18, ud, powu, mul, uUNIT} from "@prb/math/UD60x18.sol";
import {convert} from "@prb/math/ud60x18/Conversions.sol";

contract Curves {
    // Constant for 8 decimal places
    uint256 public constant DECIMAL_SCALE = 1e18; // 1e8

    // Hardcoded constants for Wheel
    uint256 public constant WHEEL_BASE_COST = 20; // Coins
    uint256 public constant WHEEL_GROWTH_FACTOR = 1150000000000000000; // 1.15e18
    uint256 public constant WHEEL_BASE_VELOCITY = 2; // Speed points

    // Hardcoded constants for Engine
    uint256 public constant ENGINE_BASE_COST = 100;
    uint256 public constant ENGINE_GROWTH_FACTOR = 1200000000000000000; // 1.20e18
    uint256 public constant ENGINE_BASE_VELOCITY = 5;

    // Hardcoded constants for Chassis
    uint256 public constant CHASSIS_BASE_COST = 10;
    uint256 public constant CHASSIS_GROWTH_FACTOR = 1100000000000000000; // 1.10e18
    uint256 public constant CHASSIS_BASE_VELOCITY = 1;

    // Hardcoded constants for Turbo
    uint256 public constant TURBO_BASE_COST = 500;
    uint256 public constant TURBO_GROWTH_FACTOR = 1250000000000000000; // 1.25e18
    uint256 public constant TURBO_BASE_VELOCITY = 3;

    // Calculate Wheel upgrade cost (exponential: baseCost * growthFactor^(level-1))
    function getWheelCost(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be at least 1");

        if (level == 1) {
            return WHEEL_BASE_COST * DECIMAL_SCALE; // Base cost with 8 decimals
        }

        // Convert to UD60x18 for fixed-point arithmetic
        UD60x18 baseCost = convert(WHEEL_BASE_COST * DECIMAL_SCALE);
        UD60x18 growthFactor = ud(WHEEL_GROWTH_FACTOR - 1e17);

        // Calculate cost = baseCost * growthFactor^(level-1)
        UD60x18 cost = mul(baseCost, powu(growthFactor, level - 1));
        return cost.unwrap() / uUNIT;
    }

    // Calculate Engine upgrade cost
    function getEngineCost(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be at least 1");

        if (level == 1) {
            return ENGINE_BASE_COST * DECIMAL_SCALE;
        }

        UD60x18 baseCost = convert(ENGINE_BASE_COST * DECIMAL_SCALE);
        UD60x18 growthFactor = ud(ENGINE_GROWTH_FACTOR - 1e17);

        UD60x18 cost = mul(baseCost, powu(growthFactor, level - 1));
        return cost.unwrap() / uUNIT;
    }

    // Calculate Chassis upgrade cost
    function getChassisCost(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be at least 1");

        if (level == 1) {
            return CHASSIS_BASE_COST * DECIMAL_SCALE;
        }

        UD60x18 baseCost = convert(CHASSIS_BASE_COST * DECIMAL_SCALE);
        UD60x18 growthFactor = ud(CHASSIS_GROWTH_FACTOR - 1e17);

        UD60x18 cost = mul(baseCost, powu(growthFactor, level - 1));
        return cost.unwrap() / uUNIT;
    }

    // Calculate Turbo upgrade cost
    function getTurboCost(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be at least 1");

        if (level == 1) {
            return TURBO_BASE_COST * DECIMAL_SCALE;
        }

        UD60x18 baseCost = convert(TURBO_BASE_COST * DECIMAL_SCALE);
        UD60x18 growthFactor = ud(TURBO_GROWTH_FACTOR - 1e17);

        UD60x18 cost = mul(baseCost, powu(growthFactor, level - 1));
        return cost.unwrap() / uUNIT;
    }

    // Calculate Wheel velocity (linear: baseVelocity * level)
    function getWheelVelocity(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be at least 1");
        return WHEEL_BASE_VELOCITY * level;
    }

    // Calculate Engine velocity
    function getEngineVelocity(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be at least 1");
        return ENGINE_BASE_VELOCITY * level;
    }

    // Calculate Chassis velocity
    function getChassisVelocity(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be at least 1");
        return CHASSIS_BASE_VELOCITY * level;
    }

    // Calculate Turbo velocity
    function getTurboVelocity(uint256 level) public pure returns (uint256) {
        require(level >= 1, "Level must be at least 1");
        return TURBO_BASE_VELOCITY * level;
    }
}
