// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./IgNFT.sol";
import "./ITPIToken.sol";
import "./IVault.sol";

/// @title  Interface for VaultFactory contract, which is a part of SegmentManagement of Tonpound gNFT token
/// @notice VaultFactory is a factory contract to store liquidity tokens in individual Vaults,
///         since Tonpound market tokens are rebasing ERC20 and TPI rewards are accrued per holder
///         Based on EIP-1167 Minimal Proxy implementation from OpenZeppelin: 
///         (https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones)
interface IVaultFactory {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason for trying to lock not supported Tonpound market
    error NotSupported();

    /// @notice Revert reason for updating implementation for address without bytecode
    error WrongImplementation();

    /// @notice Emitted with a creation of a new Vault contract to store Tonpound liquidity tokens
    /// @param market         Address of Tonpound liquidity token
    /// @param instance       Address of Vault contract to store 'market' tokens
    /// @param implementation Address of used implementation of Vault contract
    event MarketAdded(address market, address instance, address implementation);

    /// @notice Emitted when gNFT contract requests a lock of liquidity
    /// @param tokenId        gNFT tokenId to lock for
    /// @param market         Address of Tonpound market locked
    /// @param assets         Amount of Tonpound market tokens locked
    /// @param shares         Amount of shares acquired in corresponding Vault
    event Locked(uint256 indexed tokenId, address market, uint256 assets, uint256 shares);

    /// @notice Emitted when gNFT contract requests an unlock of liquidity
    /// @param tokenId        gNFT tokenId to unlock for
    /// @param market         Address of Tonpound market unlocked
    /// @param assets         Amount of Tonpound market tokens unlocked
    /// @param shares         Amount of Vault shares unlocked
    /// @param receiver       Address of receiver of unlocked liquidity
    event Unlocked(
        uint256 indexed tokenId,
        address market,
        uint256 assets,
        uint256 shares,
        address indexed receiver
    );

    /// @notice         View method to read Vault by Tonpound market
    /// @param market   Address of Tonpound market to be get Vault for
    /// @return         Vault address storing 'market' tokens (zero if not created yet)
    function vaultsByMarket(address market) external view returns (IVault);

    /// @notice         View method to get all supported markets
    /// @return         Array of supported markets, which have deployed Vaults
    function allMarkets() external view returns (address[] memory);

    /// @notice         View method to get supported market at index
    /// @return         Address of supported market at index in all markets array
    function marketAt(uint256 index) external view returns (address);

    /// @notice         View method to get number of supported numbers
    /// @return         Length of supported markets array
    function marketsLength() external view returns (uint256);

    /// @notice         View method to check if market is supported
    /// @return         True if market is supported and has Vault, False - if not
    function marketSupported(address market) external view returns (bool);
}
