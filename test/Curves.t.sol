// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Curves} from "../src/Curves.sol";

contract CurvesTest is Test {
    Curves public curves;

    function setUp() public {
        curves = new Curves();
    }

    function testCurvesValues() public {
        console.log("--- Testing Levels 1 to 10 ---");
        for (uint256 level = 1; level <= 10; level++) {
            console.log("Level:", level);
            console.log("  Wheel Cost:", curves.getWheelCost(level));
            console.log("  Engine Cost:", curves.getEngineCost(level));
            console.log("  Chassis Cost:", curves.getChassisCost(level));
            console.log("  Turbo Cost:", curves.getTurboCost(level));
            console.log("  Wheel Velocity:", curves.getWheelVelocity(level));
            console.log("  Engine Velocity:", curves.getEngineVelocity(level));
            console.log(
                "  Chassis Velocity:",
                curves.getChassisVelocity(level)
            );
            console.log("  Turbo Velocity:", curves.getTurboVelocity(level));
        }

        console.log("\n--- Testing Levels 10 to 100 (in steps of 10) ---");
        for (uint256 level = 10; level <= 100; level += 10) {
            console.log("Level:", level);
            console.log("  Wheel Cost:", curves.getWheelCost(level));
            console.log("  Engine Cost:", curves.getEngineCost(level));
            console.log("  Chassis Cost:", curves.getChassisCost(level));
            console.log("  Turbo Cost:", curves.getTurboCost(level));
            console.log("  Wheel Velocity:", curves.getWheelVelocity(level));
            console.log("  Engine Velocity:", curves.getEngineVelocity(level));
            console.log(
                "  Chassis Velocity:",
                curves.getChassisVelocity(level)
            );
            console.log("  Turbo Velocity:", curves.getTurboVelocity(level));
        }
    }
}
