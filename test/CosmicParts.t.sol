// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {CosmicParts, ICosmicParts} from "../src/CosmicParts.sol";
import {Curves} from "../src/Curves.sol";
import {IRegistry} from "../src/interfaces/IRegistry.sol";
import {IRiseCrystals} from "../src/interfaces/IRiseCrystals.sol";
import {RiseRacersTest} from "./helpers/RiseRacersTest.sol";
import {MockRiseCrystals} from "./helpers/MockRiseCrystals.sol";

// --- Test Contract ---

contract CosmicPartsTest is RiseRacersTest {
    // --- Tests for upgradePart (Minting) ---

    MockRiseCrystals mockRiseToken;

    function setUp() public override {
        super.setUp();

        // use MockRiseCrystals to set balance

        //deploy MockRiseCrystals
        mockRiseToken = new MockRiseCrystals(address(registry));

        // Set mock crystal in registry
        registry.updateContract(
            registry.RISE_CRYSTALS(),
            address(mockRiseToken)
        );
    }

    function testUpgradePart_Mint_InsufficientFunds() public {
        vm.startPrank(PLAYER_ONE);

        // Drain player balance using setter

        // Print balance of PLAYER_ONE
        console.log(mockRiseToken.balanceOf(PLAYER_ONE));

        ICosmicParts.PartType partType = ICosmicParts.PartType.Engine;
        uint256 expectedCost = cosmicParts.getEngineCost(1);

        console.log("expectedCost", expectedCost);

        // Expect revert due to low balance inside the mock 'pay' function
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)",
                PLAYER_ONE,
                0,
                expectedCost
            )
        );
        cosmicParts.upgradePart(partType);

        vm.stopPrank();
    }

    function testUpgradePart_Mint_Success() public {
        vm.startPrank(PLAYER_ONE);
        mockRiseToken.testMint(PLAYER_ONE, 1e31);

        ICosmicParts.PartType partType = ICosmicParts.PartType.Engine;
        uint256 expectedCost1e8 = cosmicParts.getEngineCost(1);
        uint256 expectedCrystalCost = expectedCost1e8 * 1e10; // Scale to 1e18
        uint256 expectedTokenId = 1; // First mint

        // Check balances before
        uint256 balanceBefore = riseToken.balanceOf(PLAYER_ONE);
        uint256 contractBalanceBefore = riseToken.balanceOf(
            address(cosmicParts)
        );

        // Perform the mint
        cosmicParts.upgradePart(partType);

        // Check NFT ownership and data
        assertEq(
            cosmicParts.ownerOf(expectedTokenId),
            PLAYER_ONE,
            "NFT Owner mismatch"
        );
        CosmicParts.CosmicPart memory partData = cosmicParts.getPartData(
            expectedTokenId
        );
        assertEq(uint(partData.partType), uint(partType), "Part type mismatch");
        assertEq(partData.level, 1, "Part level mismatch");

        // Check equipped part
        assertEq(
            cosmicParts.equippedParts(PLAYER_ONE, partType),
            expectedTokenId,
            "Equipped part mismatch"
        );

        vm.stopPrank();
    }

    // --- Tests for upgradePart (Upgrading) ---

    function testUpgradePart_Upgrade_Success() public {
        vm.startPrank(PLAYER_ONE);
        // mint 1e31 to PLAYER_ONE
        mockRiseToken.testMint(PLAYER_ONE, 1e31);

        // 1. Mint the initial part (Engine, Level 1)
        ICosmicParts.PartType partType = ICosmicParts.PartType.Engine;
        uint256 mintCost1e8 = cosmicParts.getEngineCost(1);
        uint256 mintCrystalCost = mintCost1e8 * 1e10;
        uint256 tokenId = 1; // Expecting token ID 1
        cosmicParts.upgradePart(partType); // Mint Level 1

        // 2. Prepare for upgrade (to Level 2)
        uint256 expectedNewLevel = 2;
        uint256 upgradeCost1e8 = cosmicParts.getEngineCost(expectedNewLevel);
        uint256 upgradeCrystalCost = upgradeCost1e8 * 1e10;

        // Check balances before upgrade
        uint256 balanceBeforeUpgrade = riseToken.balanceOf(PLAYER_ONE);
        uint256 contractBalanceBeforeUpgrade = riseToken.balanceOf(
            address(cosmicParts)
        );

        console.log("second upgrade");
        // 3. Perform the upgrade
        cosmicParts.upgradePart(partType);

        // Check NFT data after upgrade
        CosmicParts.CosmicPart memory partData = cosmicParts.getPartData(
            tokenId
        );
        assertEq(
            uint(partData.partType),
            uint(partType),
            "Part type mismatch post-upgrade"
        );
        assertEq(
            partData.level,
            expectedNewLevel,
            "Part level mismatch post-upgrade"
        );

        // Check equipped part is still the same token ID
        assertEq(
            cosmicParts.equippedParts(PLAYER_ONE, partType),
            tokenId,
            "Equipped part mismatch post-upgrade"
        );

        vm.stopPrank();
    }

    function testUpgradePart_Upgrade_InsufficientFunds() public {
        vm.startPrank(PLAYER_ONE);

        uint256 level1cost = cosmicParts.getEngineCost(1);

        // mint tokens
        mockRiseToken.testMint(PLAYER_ONE, level1cost);
        // 1. Mint the initial part (Engine, Level 1)
        ICosmicParts.PartType partType = ICosmicParts.PartType.Engine;
        uint256 tokenId = 1; // Expecting token ID 1
        cosmicParts.upgradePart(partType); // Mint Level 1

        // 2. Calculate upgrade cost (to Level 2)
        uint256 expectedNewLevel = 2;
        uint256 upgradeCrystalCost = cosmicParts.getEngineCost(
            expectedNewLevel
        );

        // 4. Expect revert

        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)",
                PLAYER_ONE,
                0,
                upgradeCrystalCost
            )
        );
        cosmicParts.upgradePart(partType); // Attempt upgrade

        // 5. Verify state hasn't changed (optional but good)
        CosmicParts.CosmicPart memory partData = cosmicParts.getPartData(
            tokenId
        );
        assertEq(partData.level, 1, "Part level should not have changed"); // Still Level 1

        vm.stopPrank();
    }

    // Add tests for setBaseURI and withdrawCrystals if desired
}
