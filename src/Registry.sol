// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Registry - Contract address registry for Rise Racers protocol
/// @notice Manages authorized contract addresses and their roles
contract Registry {
    // Contract roles
    bytes32 public constant RISE_RACERS = keccak256("RISE_RACERS");
    bytes32 public constant MILESTONE_TRACKER = keccak256("MILESTONE_TRACKER");
    bytes32 public constant UNIVERSE_MANAGER = keccak256("UNIVERSE_MANAGER");
    bytes32 public constant VELOCITY_MANAGER = keccak256("VELOCITY_MANAGER");
    bytes32 public constant COSMIC_PARTS = keccak256("COSMIC_PARTS");
    bytes32 public constant STAKING = keccak256("STAKING");
    bytes32 public constant RISE_CRYSTALS = keccak256("RISE_CRYSTALS");

    // Mapping from role to contract address
    mapping(bytes32 => address) public getAddress;

    // Mapping to check if an address is a registered contract
    mapping(address => bool) public isRegisteredContract;

    // Events
    event ContractRegistered(
        bytes32 indexed role,
        address indexed contractAddress
    );
    event ContractRemoved(
        bytes32 indexed role,
        address indexed contractAddress
    );
    event AuthorizationCheck(
        address indexed caller,
        address indexed target,
        address storedUniverseManager,
        address storedVelocityManager,
        bool isCallerRegistered,
        bool isTargetRegistered
    );

    // Constructor sets initial contract addresses
    constructor(
        address _riseRacers,
        address _milestoneTracker,
        address _universeManager,
        address _velocityManager,
        address _cosmicParts,
        address _staking,
        address _riseCrystals
    ) {
        _registerContract(RISE_RACERS, _riseRacers);
        _registerContract(MILESTONE_TRACKER, _milestoneTracker);
        _registerContract(UNIVERSE_MANAGER, _universeManager);
        _registerContract(VELOCITY_MANAGER, _velocityManager);
        _registerContract(COSMIC_PARTS, _cosmicParts);
        _registerContract(STAKING, _staking);
        _registerContract(RISE_CRYSTALS, _riseCrystals);
    }

    /// @notice Register a contract address for a specific role
    /// @param role The role identifier
    /// @param contractAddress The contract address to register
    function _registerContract(bytes32 role, address contractAddress) private {
        require(contractAddress != address(0), "Invalid address");
        require(getAddress[role] == address(0), "Role already registered");

        getAddress[role] = contractAddress;
        isRegisteredContract[contractAddress] = true;

        emit ContractRegistered(role, contractAddress);
    }

    /// @notice Check if a contract is authorized to interact with another contract
    /// @param caller The address of the calling contract
    /// @param target The address of the target contract
    /// @return bool True if the caller is authorized to interact with the target
    function isAuthorized(
        address caller,
        address target
    ) external returns (bool) {
        // First check if both addresses are registered contracts
        bool isCallerRegistered = isRegisteredContract[caller];
        bool isTargetRegistered = isRegisteredContract[target];

        if (!isCallerRegistered || !isTargetRegistered) {
            emit AuthorizationCheck(
                caller,
                target,
                getAddress[UNIVERSE_MANAGER],
                getAddress[VELOCITY_MANAGER],
                isCallerRegistered,
                isTargetRegistered
            );
            return false;
        }

        // Define authorization rules
        if (
            caller == getAddress[UNIVERSE_MANAGER] &&
            target == getAddress[VELOCITY_MANAGER]
        ) {
            // UniverseManager can interact with VelocityManager
            return true;
        }
        if (caller == getAddress[RISE_RACERS]) {
            // RiseRacers can interact with all other contracts
            return true;
        }
        if (
            caller == getAddress[VELOCITY_MANAGER] &&
            target == getAddress[MILESTONE_TRACKER]
        ) {
            // VelocityManager can interact with MilestoneTracker
            return true;
        }

        emit AuthorizationCheck(
            caller,
            target,
            getAddress[UNIVERSE_MANAGER],
            getAddress[VELOCITY_MANAGER],
            isCallerRegistered,
            isTargetRegistered
        );
        return false;
    }

    /// @notice Get all registered contract addresses
    function getAllContracts()
        external
        view
        returns (
            address riseRacers,
            address milestoneTracker,
            address universeManager,
            address velocityManager,
            address cosmicParts,
            address staking,
            address riseCrystals
        )
    {
        return (
            getAddress[RISE_RACERS],
            getAddress[MILESTONE_TRACKER],
            getAddress[UNIVERSE_MANAGER],
            getAddress[VELOCITY_MANAGER],
            getAddress[COSMIC_PARTS],
            getAddress[STAKING],
            getAddress[RISE_CRYSTALS]
        );
    }

    /// @notice Update a contract address after deployment (only for testing)
    function updateContract(bytes32 role, address newAddress) external {
        require(newAddress != address(0), "Invalid address");

        // Remove old registration if exists
        if (getAddress[role] != address(0)) {
            isRegisteredContract[getAddress[role]] = false;
        }

        // Update to new address
        getAddress[role] = newAddress;
        isRegisteredContract[newAddress] = true;

        emit ContractRegistered(role, newAddress);
    }

    function getRiseRacers() external view returns (address) {
        return getAddress[RISE_RACERS];
    }

    function getMilestoneTracker() external view returns (address) {
        return getAddress[MILESTONE_TRACKER];
    }

    function getUniverseManager() external view returns (address) {
        return getAddress[UNIVERSE_MANAGER];
    }

    function getVelocityManager() external view returns (address) {
        return getAddress[VELOCITY_MANAGER];
    }

    function getCosmicParts() external view returns (address) {
        return getAddress[COSMIC_PARTS];
    }

    function getStaking() external view returns (address) {
        return getAddress[STAKING];
    }

    function getRiseCrystals() external view returns (address) {
        return getAddress[RISE_CRYSTALS];
    }
}
