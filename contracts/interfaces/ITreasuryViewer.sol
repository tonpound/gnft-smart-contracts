// SPDX-License-Identifier: UNLICENSED

import "./ITreasury.sol";
import "./IOracle.sol";
import "./IInterestRateModel.sol";

pragma solidity ^0.8.4;

/// @title  Interface for Tonpound TreasuryViewer contract, which is a part of Tonpound gNFT
/// @notice Implementing interest accruing view methods
interface ITreasuryViewer {
    /// @notice             View method to get pending gNFT token rewards without state-modifying accrueInterest()
    /// @param tokenId      gNFT tokenId to calculate rewards for
    /// @param tokenWeight  Reward weigh of gNFT tokenId, can be obtained from gNFT.slot0() structure
    /// @param market       Address of Tonpound market to check rewards from
    /// @param underlying   Underlying token of given 'market'
    /// @param treasury     Address of Tonpound Treasury
    /// @return             Amount of 'underlying' rewards to be pending after distribution to Treasury
    function rewardSingleMarket(
        uint256 tokenId,
        uint8 tokenWeight,
        address market,
        address underlying,
        ITreasury treasury
    ) external view returns (uint256);

    /// @notice             View method to get pending gNFT token rewards without state-modifying accrueInterest()
    ///                     Given markets are checked and evaluated in USD using the given oracle
    /// @param tokenId      gNFT tokenId to calculate rewards for
    /// @param tokenWeight  Reward weigh of gNFT tokenId, can be obtained from gNFT.slot0() structure
    /// @param markets      Addresses of Tonpound markets to check rewards from
    /// @param underlying   Addresses of underlying tokens of given 'markets'
    /// @param decimals     Decimals of 'underlying' tokens
    /// @param oracle       Address of Tonpound Oracle
    /// @param treasury     Address of Tonpound Treasury
    /// @return             USD evaluation of 'underlying' rewards to be pending after distribution to Treasury 
    function rewardSingleIdWithEvaluation(
        uint256 tokenId,
        uint8 tokenWeight,
        address[] memory markets,
        address[] memory underlying,
        uint8[] memory decimals,
        IOracle oracle,
        ITreasury treasury
    ) external view returns (uint256);

    /// @notice             View method to get pending gNFT token rewards without state-modifying accrueInterest()
    ///                     All active markets are checked and evaluated in USD using the given oracle
    /// @param tokenIds     Array of gNFT tokenIds to calculate rewards for
    /// @param treasury     Address of Tonpound Treasury
    /// @return             Array of USD evaluations of 'underlying' rewards to be pending after distribution to Treasury 
    function rewardMultipleIdsWithEvaluation(
        uint256[] calldata tokenIds,
        ITreasury treasury
    ) external view returns (uint256[] memory);
}
