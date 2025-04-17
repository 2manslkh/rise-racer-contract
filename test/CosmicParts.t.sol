// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/CosmicParts.sol";
import "../src/interfaces/IRegistry.sol";

contract CosmicPartsTest is Test {
    CosmicParts public parts;
    address public player1 = address(1);
    address public player2 = address(2);
    IRegistry public registry;

    function setUp() public {
        parts = new CosmicParts(address(registry));
    }

    function testMintPart() public {
        vm.startPrank(parts.owner());
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Common
        );

        assertEq(parts.ownerOf(1), player1);

        (
            ICosmicParts.PartType partType,
            ICosmicParts.Rarity rarity,
            uint256 baseBoost,
            uint256 percentageBoost
        ) = parts.parts(1);

        assertEq(uint256(partType), uint256(ICosmicParts.PartType.Engine));
        assertEq(uint256(rarity), uint256(ICosmicParts.Rarity.Common));
        assertEq(baseBoost, 10); // ENGINE_BASE_BOOST
        assertEq(percentageBoost, 1); // ENGINE_PERCENT_BOOST
        vm.stopPrank();
    }

    function testCannotMintAsNonOwner() public {
        vm.startPrank(player1);
        vm.expectRevert("Only owner can mint parts");
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Common
        );
        vm.stopPrank();
    }

    function testEquipPart() public {
        // First mint a part
        vm.prank(parts.owner());
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Common
        );

        // Then equip it
        vm.startPrank(player1);
        parts.equipPart(1);

        uint256 equippedPart = parts.equippedParts(
            player1,
            ICosmicParts.PartType.Engine
        );
        assertEq(equippedPart, 1);
        vm.stopPrank();
    }

    function testCannotEquipUnownedPart() public {
        // Mint part for player1
        vm.prank(parts.owner());
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Common
        );

        // Try to equip as player2
        vm.startPrank(player2);
        vm.expectRevert("Not owner of part");
        parts.equipPart(1);
        vm.stopPrank();
    }

    function testGetTotalBoost() public {
        vm.startPrank(parts.owner());
        // Mint different parts
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Common
        ); // id: 1
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Turbo,
            ICosmicParts.Rarity.Common
        ); // id: 2
        vm.stopPrank();

        vm.startPrank(player1);
        // Equip both parts
        parts.equipPart(1);
        parts.equipPart(2);

        // Get total boost
        (uint256 baseBoost, uint256 percentBoost) = parts.getTotalBoost(
            player1
        );
        assertEq(baseBoost, 15); // ENGINE(10) + TURBO(5)
        assertEq(percentBoost, 6); // ENGINE(1) + TURBO(5)
        vm.stopPrank();
    }

    function testRarityMultipliers() public {
        vm.startPrank(parts.owner());
        // Mint same part type with different rarities
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Common
        ); // 1x
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Rare
        ); // 3x
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Epic
        ); // 6x
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Legendary
        ); // 10x
        vm.stopPrank();

        // Check each part's boosts
        (, , uint256 commonBaseBoost, uint256 commonPercentBoost) = parts.parts(
            1
        );
        (, , uint256 rareBaseBoost, uint256 rarePercentBoost) = parts.parts(2);
        (, , uint256 epicBaseBoost, uint256 epicPercentBoost) = parts.parts(3);
        (, , uint256 legendaryBaseBoost, uint256 legendaryPercentBoost) = parts
            .parts(4);

        // Base boost checks (ENGINE_BASE_BOOST = 10)
        assertEq(commonBaseBoost, 10); // 10 * 1
        assertEq(rareBaseBoost, 30); // 10 * 3
        assertEq(epicBaseBoost, 60); // 10 * 6
        assertEq(legendaryBaseBoost, 100); // 10 * 10

        // Percentage boost checks (ENGINE_PERCENT_BOOST = 1)
        assertEq(commonPercentBoost, 1); // 1 * 1
        assertEq(rarePercentBoost, 3); // 1 * 3
        assertEq(epicPercentBoost, 6); // 1 * 6
        assertEq(legendaryPercentBoost, 10); // 1 * 10
    }

    function testUnequipAndReequip() public {
        vm.startPrank(parts.owner());
        // Mint two engines
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Common
        ); // id: 1
        parts.mintPart(
            player1,
            ICosmicParts.PartType.Engine,
            ICosmicParts.Rarity.Rare
        ); // id: 2
        vm.stopPrank();

        vm.startPrank(player1);
        // Equip first engine
        parts.equipPart(1);

        // Check it's equipped
        uint256 equippedPart = parts.equippedParts(
            player1,
            ICosmicParts.PartType.Engine
        );
        assertEq(equippedPart, 1);

        // Equip second engine (should unequip first)
        parts.equipPart(2);

        // Check new equipped part
        equippedPart = parts.equippedParts(
            player1,
            ICosmicParts.PartType.Engine
        );
        assertEq(equippedPart, 2);
        vm.stopPrank();
    }
}
