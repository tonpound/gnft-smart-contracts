// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Interface for Auth contract, which is a part of gNFT token
/// @notice Authorization model is based on AccessControl and Pausable contracts from OpenZeppelin:
///         (https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl) and
///         (https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
///         Blacklisting implemented with BLACKLISTED_ROLE, managed by MANAGER_ROLE
interface IAuth {
    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice Revert reason for protected functions being called by blacklisted address
    error BlacklistedUser(address account);

    /// @notice             Check for admin role
    /// @param user         User to check for role bearing
    /// @return             True if user has the DEFAULT_ADMIN_ROLE role
    function isAdmin(address user) external view returns (bool);

    /// @notice             Check for not being in blacklist
    /// @param user         User to check for
    /// @return             True if user is not blacklisted
    function isValidUser(address user) external view returns (bool);

    /// @notice             Control function of OpenZeppelin's Pausable contract
    ///                     Restricted to PAUSER_ROLE bearers only
    /// @param newState     New boolean status for affected whenPaused/whenNotPaused functions
    function setPause(bool newState) external;
}
