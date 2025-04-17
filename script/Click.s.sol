// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/RiseRacers.sol";

contract ClickScript is Script {
    function run() external {
        // Get deployment private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Get the deployed RiseRacers contract address from environment
        address riseRacersAddress = vm.envAddress("RISE_RACERS_ADDRESS");
        RiseRacers game = RiseRacers(riseRacersAddress);

        // Call the click function
        game.click();
        console.log("Click function called successfully");

        vm.stopBroadcast();
    }
}
