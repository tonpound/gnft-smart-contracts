// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound cToken market
/// @notice Extension of IERC20 standard interface from OpenZeppelin
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20)
interface ICToken is IERC20MetadataUpgradeable {
    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves() external returns (uint256);

    /**
     * @notice Block number that interest was last accrued at
     */
    function accrualBlockNumber() external view returns(uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    function comptroller() external returns (address);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Model which tells what the current interest rate should be
     */
    function interestRateModel() external view returns (address);

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    function reserveFactorMantissa() external view returns (uint256);

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    function totalBorrows() external view returns (uint256);

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    function totalReserves() external view returns (uint256);

    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external view returns (address);
}
