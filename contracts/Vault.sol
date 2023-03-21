// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./interfaces/IVault.sol";

contract Vault is Initializable, IVault {
    using MathUpgradeable for uint256;
    using SafeCastUpgradeable for *;

    ISegmentManagement public factory;
    IERC20Upgradeable public market;
    uint256 public totalShares;
    uint256 public rewardPaid;
    uint256 public accRewardPerShare;
    uint256 public totalTPIStored;

    uint256 internal constant NOMINATOR = 1e12;
    int256 internal constant DENOMINATOR = 1e12;

    mapping(uint256 => uint256) public sharesByID;
    mapping(uint256 => int256) public rewardDebtByID;

    function initialize(address market_) external initializer {
        factory = ISegmentManagement(msg.sender);
        market = IERC20Upgradeable(market_);
    }

    function _totalTPI() internal view returns (uint256) {
        uint256 balance = _getTPIBalance();
        uint256 accrued = _getComptroller().compAccrued(address(this));
        return balance + accrued + rewardPaid;
    }

    function _getTPIBalance() internal view returns (uint256) {
        return _getTPI().balanceOf(address(this));
    }

    function totalAssets() public view returns (uint256) {
        return market.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) external view returns (uint256 shares) {
        uint256 supply = totalShares;
        return _convertToShares(assets, supply, MathUpgradeable.Rounding.Down);
    }

    function convertToAssets(uint256 shares) external view returns (uint256 assets) {
        uint256 supply = totalShares;
        return _convertToAssets(shares, supply, MathUpgradeable.Rounding.Down);
    }

    function _convertToShares(
        uint256 assets,
        uint256 supply,
        MathUpgradeable.Rounding rounding
    ) internal view virtual returns (uint256 shares) {
        return
            (assets == 0 || supply == 0) ? assets : assets.mulDiv(supply, totalAssets(), rounding);
    }

    function _convertToAssets(
        uint256 shares,
        uint256 supply,
        MathUpgradeable.Rounding rounding
    ) internal view virtual returns (uint256 assets) {
        return (supply == 0) ? shares : shares.mulDiv(totalAssets(), supply, rounding);
    }

    function _updateRewardPerShare(uint256 supply) internal returns (uint256) {
        if (supply == 0) return 0;
        uint256 total = _totalTPI();
        uint256 reward = total - totalTPIStored;
        uint256 newRewardPerShare = accRewardPerShare + (reward * NOMINATOR) / supply;
        accRewardPerShare = newRewardPerShare;
        totalTPIStored = total;
        return newRewardPerShare;
    }

    function deposit(uint256 tokenId, uint256 assets) external onlyFactory returns (uint256) {
        uint256 supply = totalShares;
        uint256 shares = _convertToShares(assets, supply, MathUpgradeable.Rounding.Down);
        uint256 updRewardPerShare = _updateRewardPerShare(supply);

        sharesByID[tokenId] += shares;
        totalShares = supply + shares;
        rewardDebtByID[tokenId] += (shares * updRewardPerShare).toInt256() / DENOMINATOR;

        emit Deposited(tokenId, assets, shares);
        return shares;
    }

    function withdraw(
        uint256 tokenId,
        uint256 shares,
        address receiver
    ) external onlyFactory returns (uint256) {
        uint256 supply = totalShares;
        uint256 assets = _convertToAssets(shares, supply, MathUpgradeable.Rounding.Down);
        uint256 updRewardPerShare = _updateRewardPerShare(supply);
        uint256 updShares = sharesByID[tokenId] - shares;

        sharesByID[tokenId] = updShares;
        totalShares = supply - shares;
        rewardDebtByID[tokenId] -= (shares * updRewardPerShare).toInt256() / DENOMINATOR;
        SafeERC20Upgradeable.safeTransfer(market, receiver, assets);
        _sentTPI(tokenId, receiver, updShares, updRewardPerShare);

        emit Withdrawn(tokenId, shares, assets);
        return assets;
    }

    function _pendingTPI(
        uint256 tokenId,
        uint256 shares,
        uint256 rewardPerShare
    ) internal view returns (uint256) {
        return
            ((shares * rewardPerShare).toInt256() / DENOMINATOR - rewardDebtByID[tokenId])
                .toUint256();
    }

    function _sentTPI(
        uint256 tokenId,
        address receiver,
        uint256 shares,
        uint256 rewardPerShare
    ) internal {
        uint256 amount = _pendingTPI(tokenId, shares, rewardPerShare);

        uint256 balance = _getTPIBalance();
        if (balance < amount) {
            _claimComp();
            if (_getTPIBalance() < amount) {
                emit NotEnoughTPI();
                return;
            }
        }
        rewardPaid += amount;
        _getTPI().transfer(receiver, amount);
    }

    function _claimComp() internal {
        address[] memory holders = new address[](1);
        holders[0] = address(this);
        address[] memory markets = new address[](1);
        markets[0] = address(market);
        _getComptroller().claimComp(holders, markets, false, true);
    }

    function pendingTPI(uint256 tokenId) external view returns (uint256) {
        uint256 supply = totalShares;
        uint256 reward = _totalTPI() - totalTPIStored;
        uint256 newRewardPerShare = accRewardPerShare + (reward * NOMINATOR) / supply;
        uint256 oldSharesByID = sharesByID[tokenId];
        return _pendingTPI(tokenId, oldSharesByID, newRewardPerShare);
    }

    function _getComptroller() internal view returns (IComptroller) {
        return factory.TONPOUND_COMPTROLLER();
    }

    function _getTPI() internal view returns (ITPIToken) {
        return factory.TPI();
    }

    modifier onlyFactory() {
        if (msg.sender != address(factory)) revert Auth();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}
