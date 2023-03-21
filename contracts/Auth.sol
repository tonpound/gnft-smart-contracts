// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IAuth.sol";

pragma solidity ^0.8.4;

abstract contract Auth is AccessControlUpgradeable, PausableUpgradeable, IAuth {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant BLACKLISTED_ROLE = keccak256("VALIDATOR_ROLE");

    function __Auth_init(address manager_, address pauser_) internal onlyInitializing {
        if (manager_ == address(0) || pauser_ == address(0)) revert ZeroAddress();
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, manager_);
        _setupRole(PAUSER_ROLE, pauser_);

        _setRoleAdmin(BLACKLISTED_ROLE, MANAGER_ROLE);
    }

    modifier validUser(address account) {
        if (hasRole(BLACKLISTED_ROLE, account)) revert BlacklistedUser(account);
        _;
    }

    function isValidUser(address account) external view returns (bool) {
        return !hasRole(BLACKLISTED_ROLE, account);
    }

    function isAdmin(address user) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, user);
    }

    function setPause(bool newState) external onlyRole(PAUSER_ROLE) {
        newState ? _pause() : _unpause();
    }
}
