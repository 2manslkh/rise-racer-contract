// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";
import "./interfaces/IRiseCrystals.sol";
import "./Curves.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract CosmicParts is ERC721URIStorage, Ownable, Curves {
    using SafeERC20 for IRiseCrystals;

    // --- Structs ---
    struct CosmicPart {
        PartType partType;
        uint256 level;
    }
    // Enums
    enum PartType {
        Engine,
        Turbo,
        Chassis,
        Wheels
    }

    // State variables
    IRegistry public registry;
    mapping(uint256 => CosmicPart) internal parts;
    mapping(address => mapping(PartType => uint256)) public equippedParts;
    mapping(PartType => uint256) public mintedSupply;
    uint256 private nextTokenId = 1;
    string private __baseURI;

    // Constants
    // uint256 public constant MAX_SUPPLY_PER_TYPE = 10000; // Removed

    // Base boosts for each part type
    uint256 private constant ENGINE_BASE_BOOST = 10;
    uint256 private constant ENGINE_PERCENT_BOOST = 1;
    uint256 private constant TURBO_BASE_BOOST = 5;
    uint256 private constant TURBO_PERCENT_BOOST = 5;
    uint256 private constant CHASSIS_BASE_BOOST = 3;
    uint256 private constant CHASSIS_PERCENT_BOOST = 3;
    uint256 private constant WHEELS_BASE_BOOST = 2;
    uint256 private constant WHEELS_PERCENT_BOOST = 2;

    // Events
    event PartMinted(
        address indexed owner,
        uint256 indexed tokenId,
        PartType partType,
        uint256 cost
    );
    event PartUpgraded(
        address indexed owner,
        uint256 indexed tokenId,
        PartType partType,
        uint256 newLevel,
        uint256 cost
    );

    constructor(
        address _registryAddress
    ) ERC721("Cosmic Parts", "CPART") Ownable(msg.sender) {
        require(_registryAddress != address(0), "Invalid registry address");
        registry = IRegistry(_registryAddress);
    }

    /**
     * @notice Upgrades the specified part type for the caller.
     * @dev If the caller does not have the part type equipped, it mints a Level 1 part.
     *      Otherwise, it upgrades the existing equipped part to the next level.
     *      Payment is required in RiseCrystals based on the curve cost.
     * @param partType The type of part to upgrade or mint.
     */
    function upgradePart(PartType partType) external {
        uint256 currentTokenId = equippedParts[msg.sender][partType];
        uint256 cost; // Cost in 1e8 scale
        uint256 crystalCost; // Cost in 1e18 scale

        if (currentTokenId == 0) {
            // Mint new Level 1 part
            require(partType <= PartType.Wheels, "Invalid PartType"); // Ensure valid enum

            // Cost for Level 1
            if (partType == PartType.Engine) cost = getEngineCost(1);
            else if (partType == PartType.Turbo) cost = getTurboCost(1);
            else if (partType == PartType.Chassis) cost = getChassisCost(1);
            else if (partType == PartType.Wheels) cost = getWheelCost(1);

            require(cost > 0, "Level 1 cost cannot be zero");
            crystalCost = cost * 1e10; // Scale to 1e18

            // Payment
            _takePayment(crystalCost);

            // Create and Assign
            uint256 newTokenId = _createPartNFT(msg.sender, partType);
            _assignEquippedPart(msg.sender, newTokenId, partType);

            // Emit Mint Event
            emit PartMinted(msg.sender, newTokenId, partType, crystalCost);
        } else {
            // Upgrade existing part
            CosmicPart storage part = parts[currentTokenId];
            // Basic check that stored partType matches requested partType (should always match)
            require(part.partType == partType, "Token data mismatch");

            uint256 currentLevel = part.level;
            uint256 nextLevel = currentLevel + 1;

            // Cost for next level
            if (partType == PartType.Engine) cost = getEngineCost(nextLevel);
            else if (partType == PartType.Turbo) cost = getTurboCost(nextLevel);
            else if (partType == PartType.Chassis)
                cost = getChassisCost(nextLevel);
            else if (partType == PartType.Wheels)
                cost = getWheelCost(nextLevel);

            require(cost > 0, "Upgrade cost cannot be zero");
            crystalCost = cost * 1e10; // Scale to 1e18

            // Payment
            _takePayment(crystalCost);

            // Apply Upgrade
            part.level = nextLevel;

            // Emit Upgrade Event
            emit PartUpgraded(
                msg.sender,
                currentTokenId,
                partType,
                nextLevel,
                crystalCost
            );
        }
    }

    // --- Internal Payment Helper ---
    function _takePayment(uint256 crystalCost) internal {
        address riseCrystalsAddress = registry.getAddress(
            registry.RISE_CRYSTALS()
        );
        require(
            riseCrystalsAddress != address(0),
            "RiseCrystals address not set"
        );
        IRiseCrystals riseCrystalsToken = IRiseCrystals(riseCrystalsAddress);
        riseCrystalsToken.pay(msg.sender, address(this), crystalCost);
    }

    // --- Internal Minting Helper (Renamed) ---
    function _createPartNFT(
        address to,
        PartType partType
    ) internal returns (uint256 tokenId) {
        mintedSupply[partType]++; // Still track total minted per type for curve input

        tokenId = nextTokenId;
        parts[tokenId] = CosmicPart({partType: partType, level: 1}); // Mint at level 1

        _mint(to, tokenId); // Actual ERC721 mint
        _setTokenURI(tokenId, _generateTokenURI(partType));

        nextTokenId++;
    }

    // --- Internal Equipping Helper (Renamed) ---
    function _assignEquippedPart(
        address player,
        uint256 tokenId,
        PartType partType
    ) internal {
        require(parts[tokenId].partType == partType, "Token ID mismatch");
        equippedParts[player][partType] = tokenId;
    }

    // --- Explicit Getter for Parts Data ---
    function getPartData(
        uint256 tokenId
    ) public view returns (CosmicPart memory) {
        return parts[tokenId]; // Return the struct directly
    }

    function getTotalBoost(
        address player
    ) external view returns (uint256 totalPower) {
        for (uint256 i = 0; i < 4; i++) {
            PartType loopPartType = PartType(i);
            uint256 equippedTokenId = equippedParts[player][loopPartType];
            if (equippedTokenId != 0) {
                if (parts[equippedTokenId].partType == loopPartType) {
                    // --- How to get boost from level? Needs separate logic ---
                    // Option 1: Use Curves.sol velocity functions?
                    // Option 2: Define boost logic here based on part.level
                    // Example using Curves velocity (assuming linear boost based on level):
                    uint256 partLevel = parts[equippedTokenId].level;
                    if (loopPartType == PartType.Engine) {
                        totalPower += getEngineVelocity(partLevel); // Example base boost
                    } else if (loopPartType == PartType.Turbo) {
                        totalPower += getTurboVelocity(partLevel);
                    } else if (loopPartType == PartType.Chassis) {
                        totalPower += getChassisVelocity(partLevel);
                    } else if (loopPartType == PartType.Wheels) {
                        totalPower += getWheelVelocity(partLevel);
                    }
                }
            }
        }
    }

    // --- Internal URI Generation ---
    function _generateTokenURI(
        PartType partType
    ) internal view returns (string memory) {
        return string(abi.encodePacked(__baseURI, uint256(partType)));
    }

    // --- Owner Functions (Remain Public) ---
    function withdrawCrystals() external onlyOwner {
        address riseCrystalsAddress = registry.getAddress(
            registry.RISE_CRYSTALS()
        );
        require(
            riseCrystalsAddress != address(0),
            "RiseCrystals address not set"
        );
        IRiseCrystals riseCrystalsToken = IRiseCrystals(riseCrystalsAddress);

        uint256 balance = riseCrystalsToken.balanceOf(address(this));
        if (balance > 0) {
            riseCrystalsToken.safeTransfer(owner(), balance);
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        __baseURI = uri;
    }

    // --- ERC721 URI Storage Overrides ---
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    // --- ERC165 Interface Support (Remains Public) ---
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
