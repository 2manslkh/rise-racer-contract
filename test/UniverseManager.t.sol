// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {UniverseManager} from "../src/UniverseManager.sol";
import {Registry} from "../src/Registry.sol";
import {IVelocityManager} from "../src/interfaces/IVelocityManager.sol";
import {RiseRacersTest} from "./helpers/RiseRacersTest.sol";

contract UniverseManagerTest is RiseRacersTest {
    function testPrintUniverseMultipliers() public {
        console.log("--- Universe Multipliers ---");

        for (uint256 i = 0; i <= 10; i++) {
            // Get the multiplier for the current (artificially set) universe level
            uint256 multiplier = universeManager.getUniverseMultiplier(i);

            console.log("Universe Level:", i, "| Multiplier:", multiplier);
        }
        console.log("--------------------------");
    }
}
