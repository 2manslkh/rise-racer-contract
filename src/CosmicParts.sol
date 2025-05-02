// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Registry.sol";
import "./interfaces/IRiseCrystals.sol";
import "./interfaces/ICosmicParts.sol";
import "./Curves.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract CosmicParts is ERC721URIStorage, ICosmicParts, Ownable, Curves {
    using SafeERC20 for IRiseCrystals;

    // State variables
    Registry public registry;
    mapping(uint256 => CosmicPart) internal parts;
    mapping(address => mapping(PartType => uint256)) public equippedParts;
    uint256 private nextTokenId = 1;
    string private __baseURI;

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
        Registry _registry
    ) ERC721("Cosmic Parts", "CPART") Ownable(msg.sender) {
        require(address(_registry) != address(0), "Invalid registry address");
        registry = _registry;
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
            crystalCost = cost;

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
            crystalCost = cost;

            // Payment
            _takePayment(crystalCost);

            // Apply Upgrade
            _updatePartNFT(currentTokenId, nextLevel);

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
        tokenId = nextTokenId;
        uint256 boost;
        if (partType == PartType.Engine) {
            boost = getEngineVelocity(1); // Example base boost
        } else if (partType == PartType.Turbo) {
            boost = getTurboVelocity(1);
        } else if (partType == PartType.Chassis) {
            boost = getChassisVelocity(1);
        } else if (partType == PartType.Wheels) {
            boost = getWheelVelocity(1);
        }
        parts[tokenId] = CosmicPart({
            partType: partType,
            level: 1,
            boost: boost
        }); // Mint at level 1

        _mint(to, tokenId); // Actual ERC721 mint
        _setTokenURI(tokenId, _generateTokenURI(partType));

        nextTokenId++;
    }

    function _updatePartNFT(uint256 tokenId, uint256 nextLevel) internal {
        CosmicPart storage part = parts[tokenId];
        part.level = nextLevel;

        uint256 boost;
        if (part.partType == PartType.Engine) {
            boost = getEngineVelocity(part.level);
        } else if (part.partType == PartType.Turbo) {
            boost = getTurboVelocity(part.level);
        } else if (part.partType == PartType.Chassis) {
            boost = getChassisVelocity(part.level);
        } else if (part.partType == PartType.Wheels) {
            boost = getWheelVelocity(part.level);
        }
        part.boost = boost;
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

    function getPartLevel(uint256 tokenId) public view returns (uint256) {
        return parts[tokenId].level;
    }

    function getPartLevelByUser(
        address player,
        PartType partType
    ) public view returns (uint256) {
        return parts[equippedParts[player][partType]].level;
    }

    function getTotalBoost(
        address player
    ) external view returns (uint256 totalPower) {
        for (uint256 i = 0; i < 4; i++) {
            PartType loopPartType = PartType(i);
            uint256 equippedTokenId = equippedParts[player][loopPartType];
            if (equippedTokenId != 0) {
                if (parts[equippedTokenId].partType == loopPartType) {
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

    function getShop(
        address user
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // get user's parts
        uint256 engineTokenId = equippedParts[user][PartType.Engine];
        uint256 turboTokenId = equippedParts[user][PartType.Turbo];
        uint256 chassisTokenId = equippedParts[user][PartType.Chassis];
        uint256 wheelsTokenId = equippedParts[user][PartType.Wheels];

        return (
            getPartLevel(engineTokenId),
            getPartLevel(turboTokenId),
            getPartLevel(chassisTokenId),
            getPartLevel(wheelsTokenId),
            getEngineCost(getPartLevel(engineTokenId) + 1),
            getTurboCost(getPartLevel(turboTokenId) + 1),
            getChassisCost(getPartLevel(chassisTokenId) + 1),
            getWheelCost(getPartLevel(wheelsTokenId) + 1)
        );
    }
}
