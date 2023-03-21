// SPDX-License-Identifier: UNLICENSED

import "./ICToken.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound Comptroller contract
/// @notice Based on Comptroller from Compound Finance with different governance model
///         (https://docs.compound.finance/v2/comptroller/)
///         Modified Comptroller stores gNFT and Treasury addresses
///         Unmodified descriptions are copied from Compound Finance GitHub repo:
///         (https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/Comptroller.sol)
interface IComptroller {
    /// @notice         Returns whether the given account is entered in the given asset
    /// @param account  The address of the account to check
    /// @param market   The market(cToken) to check
    /// @return         True if the account is in the asset, otherwise false
    function checkMembership(address account, address market) external view returns (bool);

    /// @notice         Claim all rewards accrued by the holders
    /// @param holders  The addresses to claim for
    /// @param markets  The list of markets to claim in
    /// @param bor      Whether or not to claim rewards earned by borrowing
    /// @param sup      Whether or not to claim rewards earned by supplying
    function claimComp(
        address[] memory holders,
        address[] memory markets,
        bool bor,
        bool sup
    ) external;

    /// @notice         Returns rewards accrued but not yet transferred to the user
    /// @param account  User address to get accrued rewards for
    /// @return         Value stored in compAccrued[account] mapping
    function compAccrued(address account) external view returns (uint256);

    /// @notice         Add assets to be included in account liquidity calculation
    /// @param markets  The list of addresses of the markets to be enabled
    /// @return         Success indicator for whether each corresponding market was entered
    function enterMarkets(address[] memory markets) external returns (uint256[] memory);

    /// @notice             Determine the current account liquidity wrt collateral requirements
    /// @return err         (possible error code (semi-opaque)
    ///         liquidity   account liquidity in excess of collateral requirements
    ///         shortfall   account shortfall below collateral requirements)
    function getAccountLiquidity(
        address account
    ) external view returns (uint256 err, uint256 liquidity, uint256 shortfall);

    /// @notice Return all of the markets
    /// @dev    The automatic getter may be used to access an individual market.
    /// @return The list of market addresses
    function getAllMarkets() external view returns (address[] memory);

    /// @notice         Returns the assets an account has entered
    /// @param  account The address of the account to pull assets for
    /// @return         A dynamic list with the assets the account has entered
    function getAssetsIn(address account) external view returns (address[] memory);

    /// @notice Return the address of the TPI token
    /// @return The address of TPI
    function getCompAddress() external view returns (address);

    /// @notice Return the address of the governance gNFT token
    /// @return The address of gNFT
    function gNFT() external view returns (address);

    /// @notice View function to read 'markets' mapping separately
    /// @return Market structure without nested 'accountMembership'
    function markets(address market) external view returns (Market calldata);

    /// @notice Return the address of the system Oracle
    /// @return The address of Oracle
    function oracle() external view returns (address);

    /// @notice Return the address of the Treasury
    /// @return The address of Treasury
    function treasury() external view returns (address);

    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
        bool isComped;
    }
}
