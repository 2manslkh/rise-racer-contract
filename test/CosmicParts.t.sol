// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {CosmicParts} from "../src/CosmicParts.sol";
import {Curves} from "../src/Curves.sol";
import {IRegistry} from "../src/interfaces/IRegistry.sol";
import {IRiseCrystals} from "../src/interfaces/IRiseCrystals.sol";

// --- Mock Contracts ---

// Simple mock registry (Not inheriting IRegistry to avoid abstract issues)
contract MockRegistry {
    mapping(bytes32 => address) private addresses;

    function getAddress(bytes32 key) external view returns (address) {
        return addresses[key];
    }

    function setAddress(bytes32 key, address addr) external {
        addresses[key] = addr;
    }

    // Define keys needed by CosmicParts
    function RISE_CRYSTALS() external pure returns (bytes32) {
        return keccak256("RISE_CRYSTALS");
    }
    // function CURVES() external pure returns (bytes32) { return keccak256("CURVES"); } // Not needed if Curves inherited
}

// Mock RiseCrystals token (Not inheriting IRiseCrystals)
contract MockRiseCrystals {
    mapping(address => uint256) private _balances;
    string public constant name = "Mock Rise Crystals";
    string public constant symbol = "mRISE";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    function pay(address sender, address recipient, uint256 amount) external {
        require(
            _balances[sender] >= amount,
            "MockRiseCrystals: insufficient balance"
        );
        _balances[sender] -= amount;
        _balances[recipient] += amount;
    }

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        totalSupply += amount;
    }

    // Public getter for balances mapping (matches ERC20)
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function setBalance(address account, uint256 amount) external {
        uint oldBalance = _balances[account];
        _balances[account] = amount;
        totalSupply = totalSupply - oldBalance + amount;
    }

    // --- Removed ERC20 functions not needed for mock ---
    // function transfer(...) { ... }
    // function allowance(...) { ... }
    // function approve(...) { ... }
    // function transferFrom(...) { ... }
}

// --- Test Contract ---

contract CosmicPartsTest is Test {
    CosmicParts public parts;
    Curves public curves;
    MockRegistry public registry;
    MockRiseCrystals public riseToken;

    // Declare events matching those in CosmicParts.sol
    event PartMinted(
        address indexed owner,
        uint256 indexed tokenId,
        CosmicParts.PartType partType,
        uint256 cost
    );
    event PartUpgraded(
        address indexed owner,
        uint256 indexed tokenId,
        CosmicParts.PartType partType,
        uint256 newLevel,
        uint256 cost
    );

    address public owner = address(0xBEEF); // Test owner
    address public player1 = address(0xCAFE); // Test player

    uint256 constant STARTING_BALANCE = 1_000_000 * 1e18; // 1 million tokens

    function setUp() public {
        // Deploy Mocks & Dependencies
        registry = new MockRegistry();
        riseToken = new MockRiseCrystals();
        curves = new Curves(); // Deploy actual Curves contract

        // Register addresses
        vm.prank(owner); // Assume owner sets up registry
        registry.setAddress(registry.RISE_CRYSTALS(), address(riseToken));
        // Curves contract doesn't need registration as CosmicParts inherits it now

        // Deploy CosmicParts
        // Prank as owner for deployment if Ownable constructor requires it
        vm.prank(owner);
        parts = new CosmicParts(address(registry)); // Pass registry address

        // Fund Player
        riseToken.mint(player1, STARTING_BALANCE);

        // Set Base URI (optional, but good practice)
        vm.prank(owner);
        parts.setBaseURI("test://");
    }

    // --- Tests for upgradePart (Minting) ---

    function testUpgradePart_MintNew() public {
        vm.startPrank(player1); // Player calls upgrade

        CosmicParts.PartType partType = CosmicParts.PartType.Engine;
        uint256 expectedLevel = 1;
        uint256 expectedTokenId = 1; // First mint
        uint256 expectedCost1e8 = curves.getEngineCost(expectedLevel);
        uint256 expectedCrystalCost = expectedCost1e8 * 1e10;

        // Expect payment call
        vm.expectCall(
            address(riseToken),
            abi.encodeWithSelector(
                MockRiseCrystals.pay.selector,
                player1, // sender
                address(parts), // recipient
                expectedCrystalCost // amount
            )
        );

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit PartMinted(
            player1,
            expectedTokenId,
            partType,
            expectedCrystalCost
        );

        // Perform action
        parts.upgradePart(partType);

        // --- Assertions ---
        assertEq(parts.balanceOf(player1), 1, "Player balance should be 1");
        assertEq(
            parts.ownerOf(expectedTokenId),
            player1,
            "Player should own token 1"
        );

        // Part data (Use new getter function)
        CosmicParts.CosmicPart memory partData = parts.getPartData(
            expectedTokenId
        );
        assertEq(uint(partData.partType), uint(partType), "Part type mismatch");
        assertEq(partData.level, expectedLevel, "Part level should be 1");

        // Equipped part
        assertEq(
            parts.equippedParts(player1, partType),
            expectedTokenId,
            "Part should be equipped"
        );

        // Supply
        assertEq(parts.mintedSupply(partType), 1, "Minted supply should be 1");

        // Token balance
        assertEq(
            riseToken.balanceOf(player1),
            STARTING_BALANCE - expectedCrystalCost,
            "Player balance incorrect"
        );
        assertEq(
            riseToken.balanceOf(address(parts)),
            expectedCrystalCost,
            "Contract balance incorrect"
        ); // Assuming pay transfers to contract

        // URI check (optional)
        string memory expectedBaseURI = "test://"; // From setUp
        string memory actualTokenURI = parts.tokenURI(expectedTokenId);
        // Check if the actual URI starts with the expected base URI
        bytes memory actualBytes = bytes(actualTokenURI);
        bytes memory baseBytes = bytes(expectedBaseURI);
        require(actualBytes.length >= baseBytes.length, "URI too short");
        bool prefixMatches = true;
        for (uint i = 0; i < baseBytes.length; i++) {
            if (actualBytes[i] != baseBytes[i]) {
                prefixMatches = false;
                break;
            }
        }
        assertTrue(
            prefixMatches,
            "Token URI does not start with correct base URI"
        );
        // Could also check the suffix part: string(abi.encodePacked(uint256(partType)))

        vm.stopPrank();
    }

    function testUpgradePart_Mint_InsufficientFunds() public {
        vm.startPrank(player1);

        // Drain player balance using setter
        riseToken.setBalance(player1, 1);

        CosmicParts.PartType partType = CosmicParts.PartType.Engine;
        uint256 expectedCost1e8 = curves.getEngineCost(1);
        uint256 expectedCrystalCost = expectedCost1e8 * 1e10;

        // Expect revert due to low balance inside the mock 'pay' function
        // Note: The exact revert message depends on the mock implementation.
        // If safeTransferFrom was used, it would be "ERC20: transfer amount exceeds balance"
        vm.expectRevert(bytes("MockRiseCrystals: insufficient balance"));

        parts.upgradePart(partType);

        vm.stopPrank();
    }

    // --- Tests for upgradePart (Upgrading) ---

    function testUpgradePart_UpgradeExisting() public {
        testUpgradePart_MintNew();
        vm.startPrank(player1);

        CosmicParts.PartType partType = CosmicParts.PartType.Engine;
        uint256 currentTokenId = 1; // From previous mint
        uint256 expectedOldLevel = 1;
        uint256 expectedNewLevel = 2;
        uint256 expectedCost1e8 = curves.getEngineCost(expectedNewLevel); // Cost for level 2
        uint256 expectedCrystalCost = expectedCost1e8 * 1e10;
        uint256 balanceBeforeUpgrade = riseToken.balanceOf(player1);

        // Expect payment call
        vm.expectCall(
            address(riseToken),
            abi.encodeWithSelector(
                MockRiseCrystals.pay.selector,
                player1, // sender
                address(parts), // recipient
                expectedCrystalCost // amount
            )
        );

        // Expect event
        vm.expectEmit(true, true, true, true);
        emit PartUpgraded(
            player1,
            currentTokenId,
            partType,
            expectedNewLevel,
            expectedCrystalCost
        );

        // Perform action
        parts.upgradePart(partType);

        // --- Assertions ---
        assertEq(
            parts.balanceOf(player1),
            1,
            "Player balance should still be 1"
        );
        assertEq(
            parts.ownerOf(currentTokenId),
            player1,
            "Player should still own token 1"
        );

        // Part data (Use new getter function)
        CosmicParts.CosmicPart memory partData = parts.getPartData(
            currentTokenId
        );
        assertEq(uint(partData.partType), uint(partType), "Part type mismatch");
        assertEq(partData.level, expectedNewLevel, "Part level should be 2");

        // Equipped part (unchanged)
        assertEq(
            parts.equippedParts(player1, partType),
            currentTokenId,
            "Part should still be equipped"
        );

        // Supply (unchanged for upgrade)
        assertEq(
            parts.mintedSupply(partType),
            1,
            "Minted supply should still be 1"
        );

        // Token balance
        assertEq(
            riseToken.balanceOf(player1),
            balanceBeforeUpgrade - expectedCrystalCost,
            "Player balance incorrect after upgrade"
        );

        vm.stopPrank();
    }

    function testUpgradePart_Upgrade_InsufficientFunds() public {
        // Mint Level 1 part first
        testUpgradePart_MintNew();

        vm.startPrank(player1);

        // Drain player balance using setter
        riseToken.setBalance(player1, 1);

        CosmicParts.PartType partType = CosmicParts.PartType.Engine;
        uint256 expectedCost1e8 = curves.getEngineCost(2); // Cost for level 2
        uint256 expectedCrystalCost = expectedCost1e8 * 1e10;

        // Expect revert
        vm.expectRevert(bytes("MockRiseCrystals: insufficient balance"));

        parts.upgradePart(partType);

        vm.stopPrank();
    }

    // Add tests for setBaseURI and withdrawCrystals if desired
}
