// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICosmicParts.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IRiseCrystals.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract CosmicParts is ICosmicParts, ERC721URIStorage, Ownable {
    using SafeERC20 for IRiseCrystals;

    // State variables
    IRegistry public registry;
    mapping(uint256 => CosmicPart) public parts;
    mapping(address => mapping(PartType => uint256)) public equippedParts;
    mapping(PartType => mapping(Rarity => uint256)) public mintedSupply;
    uint256 private nextTokenId = 1;

    // Constants
    uint256 public constant BASE_CRYSTAL_MINT_COST = 10000 ether;
    uint256 public constant MAX_SUPPLY_PER_TYPE = 10000;

    // Base boosts for each part type
    uint256 private constant ENGINE_BASE_BOOST = 10;
    uint256 private constant ENGINE_PERCENT_BOOST = 1; // 100%
    uint256 private constant TURBO_BASE_BOOST = 5;
    uint256 private constant TURBO_PERCENT_BOOST = 5; // 500%
    uint256 private constant CHASSIS_BASE_BOOST = 3;
    uint256 private constant CHASSIS_PERCENT_BOOST = 3; // 300%
    uint256 private constant WHEELS_BASE_BOOST = 2;
    uint256 private constant WHEELS_PERCENT_BOOST = 2; // 200%

    // Events
    event PartMinted(
        address indexed to,
        uint256 indexed tokenId,
        PartType partType,
        Rarity rarity
    );
    event PartEquipped(
        address indexed player,
        uint256 indexed tokenId,
        PartType partType
    );

    constructor(
        address _registryAddress
    ) ERC721("Cosmic Parts", "CPART") Ownable(msg.sender) {
        require(_registryAddress != address(0), "Invalid registry address");
        registry = IRegistry(_registryAddress);
    }

    /**
     * @notice Mints a new Cosmic Part NFT, requiring payment in RiseCrystals and checking max supply.
     * @dev Caller must have approved this contract to spend sufficient RiseCrystals beforehand.
     * @param to The address to mint the part to.
     * @param partType The type of the part.
     * @param rarity The rarity of the part.
     */
    function mintPart(
        address to,
        PartType partType,
        Rarity rarity
    ) external override {
        require(
            mintedSupply[partType][rarity] < MAX_SUPPLY_PER_TYPE,
            "Max supply reached for this part type"
        );

        mintedSupply[partType][rarity]++;

        (uint256 baseBoost, uint256 percentBoost) = _getBoostValues(
            partType,
            rarity
        );

        require(baseBoost > 0 && percentBoost > 0, "Boosts cannot be zero");
        uint256 crystalCost = BASE_CRYSTAL_MINT_COST * baseBoost * percentBoost;

        address riseCrystalsAddress = registry.getAddress(
            registry.RISE_CRYSTALS()
        );
        require(
            riseCrystalsAddress != address(0),
            "RiseCrystals address not set in Registry"
        );
        IRiseCrystals riseCrystalsToken = IRiseCrystals(riseCrystalsAddress);

        riseCrystalsToken.safeTransferFrom(
            msg.sender,
            address(this),
            crystalCost
        );

        uint256 currentTokenId = nextTokenId;
        parts[currentTokenId] = CosmicPart({
            partType: partType,
            rarity: rarity,
            baseBoost: baseBoost,
            percentageBoost: percentBoost
        });

        _mint(to, currentTokenId);
        _setTokenURI(currentTokenId, _generateTokenURI(partType, rarity));
        emit PartMinted(to, currentTokenId, partType, rarity);
        nextTokenId++;
    }

    function getTotalBoost(
        address player
    )
        external
        view
        override
        returns (uint256 baseBoost, uint256 percentageBoost)
    {
        for (uint256 i = 0; i < 4; i++) {
            PartType partType = PartType(i);
            uint256 equippedTokenId = equippedParts[player][partType];
            if (equippedTokenId != 0) {
                CosmicPart storage part = parts[equippedTokenId];
                baseBoost += part.baseBoost;
                percentageBoost += part.percentageBoost;
            }
        }
    }

    function getTotalBoostValue(
        address player
    ) external view returns (uint256) {
        uint256 totalBaseBoost = 1;
        uint256 totalPercentageBoost = 0;
        uint256 totalBoostValue = 1;
        for (uint256 i = 0; i < 4; i++) {
            PartType partType = PartType(i);
            uint256 equippedTokenId = equippedParts[player][partType];
            if (equippedTokenId != 0) {
                CosmicPart storage part = parts[equippedTokenId];
                totalBaseBoost += part.baseBoost;
                totalPercentageBoost += part.percentageBoost;
            }
        }
        totalBoostValue = totalBaseBoost * totalPercentageBoost;
        return (totalBoostValue);
    }

    /**
     * @notice Equips a part NFT, which also burns the NFT.
     * @param tokenId The ID of the part NFT to equip.
     */
    function equipPart(uint256 tokenId) external override {
        require(_ownerOf(tokenId) != address(0), "Part does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not owner of part");

        CosmicPart storage part = parts[tokenId];
        address player = msg.sender;

        uint256 currentEquipped = equippedParts[player][part.partType];
        if (currentEquipped != 0) {
            equippedParts[player][part.partType] = 0;
        }

        equippedParts[player][part.partType] = tokenId;
        emit PartEquipped(player, tokenId, part.partType);

        _burn(tokenId);
    }

    // Internal functions
    function _getBoostValues(
        PartType partType,
        Rarity rarity
    ) internal pure returns (uint256 baseBoost, uint256 percentBoost) {
        uint256 rarityMultiplier;
        if (rarity == Rarity.Common) rarityMultiplier = 1;
        else if (rarity == Rarity.Rare) rarityMultiplier = 3;
        else if (rarity == Rarity.Epic) rarityMultiplier = 6;
        else if (rarity == Rarity.Legendary) rarityMultiplier = 10;

        if (partType == PartType.Engine) {
            baseBoost = ENGINE_BASE_BOOST * rarityMultiplier;
            percentBoost = ENGINE_PERCENT_BOOST * rarityMultiplier;
        } else if (partType == PartType.Turbo) {
            baseBoost = TURBO_BASE_BOOST * rarityMultiplier;
            percentBoost = TURBO_PERCENT_BOOST * rarityMultiplier;
        } else if (partType == PartType.Chassis) {
            baseBoost = CHASSIS_BASE_BOOST * rarityMultiplier;
            percentBoost = CHASSIS_PERCENT_BOOST * rarityMultiplier;
        } else if (partType == PartType.Wheels) {
            baseBoost = WHEELS_BASE_BOOST * rarityMultiplier;
            percentBoost = WHEELS_PERCENT_BOOST * rarityMultiplier;
        }
    }

    function _generateTokenURI(
        PartType partType,
        Rarity rarity
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "part/",
                    uint256(partType),
                    "/",
                    uint256(rarity)
                )
            );
    }

    /**
     * @notice Allows the owner to withdraw accumulated RiseCrystals tokens from this contract.
     */
    function withdrawCrystals() external onlyOwner {
        address riseCrystalsAddress = registry.getAddress(
            registry.RISE_CRYSTALS()
        );
        require(
            riseCrystalsAddress != address(0),
            "RiseCrystals address not set in Registry"
        );
        IRiseCrystals riseCrystalsToken = IRiseCrystals(riseCrystalsAddress);

        uint256 balance = riseCrystalsToken.balanceOf(address(this));
        if (balance > 0) {
            riseCrystalsToken.safeTransfer(owner(), balance);
        }
    }
}
