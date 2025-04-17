// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface for the Registry contract
 * @dev Defines the functions needed to interact with the Registry,
 *      specifically to retrieve registered contract addresses.
 */
interface IRegistry {
    // Role constants needed by other contracts
    function STAKING() external view returns (bytes32);

    function RISE_CRYSTALS() external view returns (bytes32);

    function COSMIC_PARTS() external view returns (bytes32);

    /**
     * @notice Get the registered address for a specific role.
     * @param role The role identifier (e.g., STAKING()).
     * @return The address registered for the given role.
     */
    function getAddress(bytes32 role) external view returns (address);
}
