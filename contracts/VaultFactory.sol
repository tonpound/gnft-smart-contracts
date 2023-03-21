// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./Constants.sol";
import "./interfaces/IVaultFactory.sol";

abstract contract VaultFactory is Initializable, IVaultFactory {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    IVault public vaultImplementation;

    EnumerableSetUpgradeable.AddressSet private _markets;
    mapping(address => IVault) public vaultsByMarket;

    function __VaultFactory_init(address vault_) internal onlyInitializing {
        vaultImplementation = IVault(vault_);
    }

    function _getVault(address market) internal returns (IVault) {
        IVault vault;
        if (market == _getTPIAddress()) revert NotSupported();
        if (_markets.add(market)) {
            address implementation = address(vaultImplementation);
            vault = IVault(ClonesUpgradeable.clone(implementation));
            vault.initialize(market);
            vaultsByMarket[market] = vault;

            emit MarketAdded(market, address(vault), implementation);
        } else {
            vault = vaultsByMarket[market];
        }
        return vault;
    }

    function _vaultLock(
        uint256 tokenId,
        address market,
        uint256 assets,
        address sender
    ) internal returns (uint256) {
        IVault vault = _getVault(market);
        uint256 shares = vault.deposit(tokenId, assets);
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(market),
            sender,
            address(vault),
            assets
        );

        emit Locked(tokenId, market, assets, shares);
        return shares;
    }

    function _vaultUnlock(
        uint256 tokenId,
        address market,
        uint256 shares,
        address receiver
    ) internal returns (uint256) {
        IVault vault = _getVault(market);
        uint256 assets = vault.withdraw(tokenId, shares, receiver);

        emit Unlocked(tokenId, market, assets, shares, receiver);
        return assets;
    }

    function allMarkets() external view returns (address[] memory) {
        return _markets.values();
    }

    function marketAt(uint256 index) external view returns (address) {
        return _markets.at(index);
    }

    function marketsLength() external view returns (uint256) {
        return _markets.length();
    }

    function marketSupported(address market) external view returns (bool) {
        return _markets.contains(market);
    }

    function _getTPIAddress() internal view virtual returns (address) {}

    function _updateImplementation(address implementation) internal {
        if (!AddressUpgradeable.isContract(implementation)) revert WrongImplementation();
        vaultImplementation = IVault(implementation);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}
