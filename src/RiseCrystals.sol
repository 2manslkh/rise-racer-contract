// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
// Remove Ownable and AccessControl if not used elsewhere
// import "openzeppelin-contracts/access/AccessControl.sol";
// import "openzeppelin-contracts/access/Ownable.sol";
import "./interfaces/IRegistry.sol"; // Import the Registry interface

contract RiseCrystals is ERC20 {
    IRegistry public registry;

    modifier onlyStakingContract() {
        // Ensure registry is not address(0) before calling it
        require(address(registry) != address(0), "Registry not set");
        address stakingAddress = registry.getAddress(registry.STAKING());
        require(
            stakingAddress != address(0),
            "Staking address not set in Registry"
        );
        require(
            msg.sender == stakingAddress,
            "Caller is not the Staking contract"
        );
        _;
    }

    constructor(address _registryAddress) ERC20("Rise Crystals", "RISE") {
        require(_registryAddress != address(0), "Invalid registry address");
        registry = IRegistry(_registryAddress);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - The caller must be the registered Staking contract.
     */
    function mint(address account, uint256 amount) public onlyStakingContract {
        _mint(account, amount);
    }

    /**
     * @dev Overrides the internal {_spendAllowance} function to allow the
     * registered CosmicParts contract to spend tokens without explicit approval.
     * For all other spenders, it behaves identically to the standard ERC20 implementation.
     * @param owner The address of the token owner.
     * @param spender The address of the spender.
     * @param amount The amount of tokens to spend.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        // Ensure registry is set before attempting to use it
        if (address(registry) != address(0)) {
            address cosmicPartsAddress = registry.getAddress(
                registry.COSMIC_PARTS()
            );
            // Check if the spender is the registered CosmicParts contract
            if (
                spender == cosmicPartsAddress &&
                cosmicPartsAddress != address(0)
            ) {
                // If it is, skip the allowance check and deduction.
                // The transfer itself (in _transfer) will still check the owner's balance.
                return;
            }
        }
        // If the spender is not the CosmicParts contract, or if the registry/address isn't set,
        // fall back to the standard ERC20 allowance check.
        super._spendAllowance(owner, spender, amount);
    }

    // Optional: Function to update the registry address if needed (add access control like onlyOwner if re-introducing Ownable)
    // function setRegistry(address _newRegistryAddress) external { // Add appropriate access control
    //     require(_newRegistryAddress != address(0), "Invalid registry address");
    //     registry = IRegistry(_newRegistryAddress);
    // }
}
