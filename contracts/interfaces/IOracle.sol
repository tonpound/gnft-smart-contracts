// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Partial interface for Oracle contract
/// @notice Based on PriceOracle from Compound Finance
///         (https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/PriceOracle.sol)
interface IOracle {
    /// @notice         Get the underlying price of a market(cToken) asset
    /// @param market   The market to get the underlying price of
    /// @return         The underlying asset price mantissa (scaled by 1e18).
    ///                 Zero means the price is unavailable.
    function getUnderlyingPrice(address market) external view returns (uint256);

    /// @notice         Evaluates input amount according to stored price, accrues interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken'
    ///                     true - return cTokens equal to 'amount' of USD
    function getEvaluation(address cToken, uint256 amount, bool reverse) external returns (uint256);

    /// @notice         Evaluates input amount according to stored price, doesn't accrue interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken'
    ///                     true - return cTokens equal to 'amount' of USD
    function getEvaluationStored(
        address cToken,
        uint256 amount,
        bool reverse
    ) external view returns (uint256);
}
