// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
// Remove Ownable and AccessControl if not used elsewhere
// import "openzeppelin-contracts/access/AccessControl.sol";
// import "openzeppelin-contracts/access/Ownable.sol";
import "./Registry.sol"; // Import the Registry interface

contract RiseCrystals is ERC20 {
    Registry public registry;

    modifier onlyAllowedContract() {
        // Ensure registry is not address(0) before calling it
        require(address(registry) != address(0), "Registry not set");

        address stakingAddress = registry.getStaking();
        address riseRacersAddress = registry.getRiseRacers();

        require(
            stakingAddress != address(0) && riseRacersAddress != address(0),
            "Required addresses not set in Registry"
        );

        require(
            msg.sender == stakingAddress || msg.sender == riseRacersAddress,
            "Caller is not an allowed contract"
        );
        _;
    }

    constructor(address _registryAddress) ERC20("Rise Crystals", "RISE") {
        require(_registryAddress != address(0), "Invalid registry address");
        registry = Registry(_registryAddress);
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
    function mint(address account, uint256 amount) public onlyAllowedContract {
        _mint(account, amount);
    }

    /**
     * @dev Allows the CosmicParts contract to pay for upgrades.
     * @param from The address of the sender.
     * @param to The address of the recipient.
     * @param value The amount of tokens to transfer.
     * @return true if the transfer was successful.
     */
    function pay(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        // Only the CosmicParts contract can use this function
        address spender = registry.getAddress(registry.COSMIC_PARTS());
        require(
            msg.sender == spender,
            "Only CosmicParts contract can call this function"
        );
        _transfer(from, to, value);
        return true;
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
