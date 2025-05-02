// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Curves} from "../src/Curves.sol";

contract CurvesTest is Test {
    Curves public curves;

    function setUp() public {
        curves = new Curves();
    }

    function test_PrintCurveValues() public {
        uint256 maxLevelToTest = 20; // Adjust as needed

        console.log("--- Upgrade Curve Values ---");

        for (uint256 level = 1; level <= maxLevelToTest; level++) {
            console.log("\n--- Level:", level, "---");

            // Wheel
            uint256 wheelCost = curves.getWheelCost(level);
            uint256 wheelVel = curves.getWheelVelocity(level);
            console.log(
                "  Wheel   | Cost:",
                wheelCost,
                " | Velocity:",
                wheelVel
            );

            // Engine
            uint256 engineCost = curves.getEngineCost(level);
            uint256 engineVel = curves.getEngineVelocity(level);
            console.log(
                "  Engine  | Cost:",
                engineCost,
                " | Velocity:",
                engineVel
            );

            // Chassis
            uint256 chassisCost = curves.getChassisCost(level);
            uint256 chassisVel = curves.getChassisVelocity(level);
            console.log(
                "  Chassis | Cost:",
                chassisCost,
                " | Velocity:",
                chassisVel
            );

            // Turbo
            uint256 turboCost = curves.getTurboCost(level);
            uint256 turboVel = curves.getTurboVelocity(level);
            console.log(
                "  Turbo   | Cost:",
                turboCost,
                " | Velocity:",
                turboVel
            );
        }
        console.log("\n---------------------------");
    }
}
