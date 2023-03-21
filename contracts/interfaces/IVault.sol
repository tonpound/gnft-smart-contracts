// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./ISegmentManagement.sol";

/// @title  Interface for Tonpound gNFT Vault contract, which is a part of gNFT token
/// @notice VaultFactory is called by VaultFactory contract to store underlying Tonpound liquidity tokens
///         Vault contract is based on ERC4626 Vault from OpenZeppelin's library:
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC4626)
interface IVault {
    /// @notice         Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice         Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice         Emitted when problem in TPI calculation arises
    event NotEnoughTPI();

    /// @notice         Emitted with each deposit act
    /// @param tokenId  Deposit is linked to gNFT tokenId
    /// @param assets   Tonpound market cToken amount being deposited
    /// @param shares   Equivalent amount of shares calculated at the moment
    event Deposited(uint256 tokenId, uint256 assets, uint256 shares);

    /// @notice         Emitted with each withdraw act
    /// @param tokenId  Withdraw is linked to gNFT tokenId
    /// @param shares   Amount of shares to be withdrawn
    /// @param assets   Market cToken amount calculated at the moment
    event Withdrawn(uint256 tokenId, uint256 shares, uint256 assets);

    /// @notice         Method to be called by VaultFactory when locking is requested by gNFT
    /// @param tokenId  gNFT tokenId to deposit for
    /// @param assets   Amount of Tonpound market tokens to be deposited
    /// @return shares  Amount of shares acquired from 'assets' amount
    function deposit(uint256 tokenId, uint256 assets) external returns (uint256 shares);

    /// @notice         Method to be called by VaultFactory when unlocking is requested by gNFT
    /// @param tokenId  gNFT tokenId to withdraw for
    /// @param shares   Amount of Vault shares to be redeemed
    /// @return assets  Amount of assets acquired from 'shares' amount
    function withdraw(
        uint256 tokenId,
        uint256 shares,
        address receiver
    ) external returns (uint256 assets);

    /// @notice         View method to get shares from assets
    /// @param assets   Amount of underlying asset tokens
    /// @return shares  Amount of shares to be acquired from 'assets'
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice         View method to get assets from shares
    /// @param shares   Amount of Vault shares
    /// @return assets  Amount of underlying assets to be acquired from 'shares'
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /// @notice         View method to get total stored assets
    /// @return         Underlying assets balance of Vault contract
    function totalAssets() external view returns (uint256);

    /// @notice         View method to get total shares
    /// @return         Total amount of minted Vault shares
    function totalShares() external view returns (uint256);

    /// @notice         View method to get underlying asset address
    /// @return         Address of Tonpound market used as storing asset
    function market() external view returns (IERC20Upgradeable);

    /// @notice         View method to get Tonpound gNFT SegmentManagement contract
    /// @return         Address of SegmentManagement contract, which has access to restricted functions
    function factory() external view returns (ISegmentManagement);

    /// @notice         View method to get TPI reward per share
    /// @return         Stored accumulated TPI reward per share
    function accRewardPerShare() external view returns (uint256);

    /// @notice         View method to get stored TPI rewards
    /// @return         Total amount of TPI rewards stored with the last update
    function totalTPIStored() external view returns (uint256);

    /// @notice         View method to get already paid TPI
    /// @return         Total amount of TPI rewards paid to unlocked gNFTs
    function rewardPaid() external view returns (uint256);

    /// @notice         View method to get Vault shares by gNFT tokenID
    /// @return         Amount of shares in the Vault
    function sharesByID(uint256) external view returns (uint256);

    /// @notice         View method to get reward debt by gNFT tokenID,
    ///                 i.e. accRewardPerShare at the moment of balance update
    ///                 Can be negative, so rewards are claimable even after shares withdrawal
    /// @return         rewardDebt = SUM_OF (sharesDiff * accRewardPerShare)_i
    function rewardDebtByID(uint256) external view returns (int256);

    /// @notice         Restricted initializer to be called right after Vault creation
    /// @param market   Address of Tonpound market used as storing asset
    function initialize(address market) external;
}
