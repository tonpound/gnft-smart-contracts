// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Constants.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ICToken.sol";

pragma solidity 0.8.17;

contract Treasury is UUPSUpgradeable, ReentrancyGuardUpgradeable, ITreasury {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IComptroller public TONPOUND_COMPTROLLER;
    uint64 internal _REWARD_CLAIM_START;
    address public reserveFund;
    uint256 public reserveBPS;
    uint256 public totalRegisteredWeight;

    mapping(address => mapping(uint256 => uint256)) public fixedRewardPayments;
    mapping(address => mapping(uint256 => uint256)) public lastClaimForTokenId;
    mapping(address => uint256) public rewardPerShare;
    mapping(address => uint256) public rewardBalance;
    mapping(uint256 => bool) public registeredTokenIds;

    EnumerableSetUpgradeable.AddressSet internal rewardTokens;

    function initialize(address comptroller_) external initializer {
        if (comptroller_ == address(0)) revert ZeroAddress();
        __UUPSUpgradeable_init();

        TONPOUND_COMPTROLLER = IComptroller(comptroller_);
        _REWARD_CLAIM_START = uint64(block.timestamp + Constants.REWARD_ACCUMULATING_PERIOD);
    }

    function distributeRewards() external {
        address[] memory tokens = TONPOUND_COMPTROLLER.getAllMarkets();
        _distributeInternal(tokens);
    }

    function distributeReward(address market) external {
        if (!TONPOUND_COMPTROLLER.markets(market).isListed) revert InvalidMarket();
        address[] memory tokens = new address[](1);
        tokens[0] = market;
        _distributeInternal(tokens);
    }

    function _distributeInternal(address[] memory tokens) internal {
        uint256 latestSupply = totalRegisteredWeight;
        address resAddress = reserveFund;
        uint256 resFactorBPS = reserveBPS;
        uint256 updRewardBalance;
        uint256 amount;
        uint256 reserveAmount;
        address underlyingToken;
        bool takeReserve = (resAddress != address(0) && resFactorBPS > 0);
        for (uint256 i; i < tokens.length; ) {
            ICToken(tokens[i])._reduceReserves();
            underlyingToken = ICToken(tokens[i]).underlying();
            updRewardBalance = IERC20Upgradeable(underlyingToken).balanceOf(address(this));
            amount = updRewardBalance - rewardBalance[tokens[i]];
            if (takeReserve) {
                reserveAmount = (amount * resFactorBPS) / Constants.DENOM_BPS;
                IERC20Upgradeable(underlyingToken).safeTransfer(resAddress, reserveAmount);
            }
            unchecked {
                if (_updateRewards(underlyingToken, amount - reserveAmount, latestSupply)) {
                    rewardBalance[underlyingToken] = updRewardBalance - reserveAmount;
                }
                i++;
            }
        }
    }

    function _updateRewards(
        address rewardToken,
        uint256 amount,
        uint256 supply
    ) internal returns (bool) {
        uint256 curRewardPerShare = rewardPerShare[rewardToken];
        if (curRewardPerShare == 0) {
            rewardTokens.add(rewardToken);
        }
        if (supply == 0) {
            return false;
        }
        rewardPerShare[rewardToken] =
            curRewardPerShare +
            (amount * Constants.EXP_REWARD_PER_SHARE) /
            supply;
        return true;
    }

    function registerTokenId(uint256 tokenId, bool state) external nonReentrant {
        IgNFT gNft = _getgNFTAddress();
        if (msg.sender != address(gNft.SEGMENT_MANAGEMENT())) revert Auth();
        if (state == registeredTokenIds[tokenId]) return;

        uint256 deltaWeight = gNft.getTokenSlot0(tokenId).rewardWeight;
        uint256 updRegisteredWeight = state
            ? totalRegisteredWeight + deltaWeight
            : totalRegisteredWeight - deltaWeight;
        totalRegisteredWeight = updRegisteredWeight;
        uint256 length = rewardTokens.length();
        for (uint256 i; i < length; ) {
            address rewardToken = rewardTokens.at(i);
            if (!state) {
                fixedRewardPayments[rewardToken][tokenId] = _pendingReward(
                    tokenId,
                    rewardToken,
                    gNft
                );
            }
            lastClaimForTokenId[rewardToken][tokenId] = state ? rewardPerShare[rewardToken] : 0;
            unchecked {
                i++;
            }
        }
        registeredTokenIds[tokenId] = state;
    }

    function pendingReward(address rewardToken, uint256 tokenId) external view returns (uint256) {
        IgNFT gNft = _getgNFTAddress();
        return _pendingReward(tokenId, rewardToken, gNft);
    }

    function _pendingReward(
        uint256 tokenId,
        address rewardToken,
        IgNFT gNft
    ) internal view returns (uint256) {
        uint8 weight = gNft.getTokenSlot0(tokenId).rewardWeight;
        uint256 curRewardPerShare = rewardPerShare[rewardToken];
        uint256 pendingPart = registeredTokenIds[tokenId]
            ? (weight * (curRewardPerShare - lastClaimForTokenId[rewardToken][tokenId])) /
                Constants.EXP_REWARD_PER_SHARE
            : 0;
        return fixedRewardPayments[rewardToken][tokenId] + pendingPart;
    }

    function claimRewards(uint256 tokenId) external whenNotPaused nonReentrant {
        IgNFT gNft = _getgNFTAddress();
        _validateClaiming(tokenId, address(gNft));
        uint256 length = rewardTokens.length();
        for (uint256 i; i < length; ) {
            _claimRewardInternal(tokenId, rewardTokens.at(i), gNft);
            unchecked {
                i++;
            }
        }
    }

    function claimReward(uint256 tokenId, address rewardToken) external whenNotPaused nonReentrant {
        IgNFT gNft = _getgNFTAddress();
        _validateClaiming(tokenId, address(gNft));
        if (!rewardTokens.contains(rewardToken)) revert InvalidRewardToken();
        _claimRewardInternal(tokenId, rewardToken, gNft);
    }

    function _claimRewardInternal(uint256 tokenId, address rewardToken, IgNFT gNft) internal {
        uint256 reward;
        uint256 pendingPart;
        if (registeredTokenIds[tokenId]) {
            uint8 weight = gNft.getTokenSlot0(tokenId).rewardWeight;
            uint256 curRewardPerShare = rewardPerShare[rewardToken];
            pendingPart =
                (weight * (curRewardPerShare - lastClaimForTokenId[rewardToken][tokenId])) /
                Constants.REWARD_PER_SHARE_MULTIPLIER;
            lastClaimForTokenId[rewardToken][tokenId] = curRewardPerShare;
        }
        reward = fixedRewardPayments[rewardToken][tokenId] + pendingPart;
        fixedRewardPayments[rewardToken][tokenId] = 0;
        rewardBalance[rewardToken] -= reward;
        IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, reward);
    }

    function _validateClaiming(uint256 tokenId, address gNft) internal view {
        if (rewardsClaimRemaining() > 0) revert ClaimingNotStarted();
        if (msg.sender != IERC721Upgradeable(gNft).ownerOf(tokenId)) revert InvalidTokenOwnership();
    }

    function rewardsClaimRemaining() public view returns (uint256) {
        uint256 claimTimestamp = uint256(_REWARD_CLAIM_START);
        if (block.timestamp > claimTimestamp) {
            return 0;
        }
        unchecked {
            return claimTimestamp - block.timestamp;
        }
    }

    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens.values();
    }

    function getRewardTokensLength() external view returns (uint256) {
        return rewardTokens.length();
    }

    function getRewardTokensAtIndex(uint256 index) external view returns (address) {
        return rewardTokens.at(index);
    }

    function _getgNFTAddress() internal view returns (IgNFT) {
        return IgNFT(TONPOUND_COMPTROLLER.gNFT());
    }

    function setReserveFactor(uint256 newReserveBPS) external onlyAdmin {
        if (newReserveBPS > Constants.MAX_RESERVE_BPS) {
            revert InvalidParameter();
        }
        emit ReserveFactorUpdated(reserveBPS, newReserveBPS);
        reserveBPS = newReserveBPS;
    }

    function setReserveFund(address newReserveFund) external onlyAdmin {
        if (newReserveFund == address(0)) {
            revert ZeroAddress();
        }
        emit ReserveFundUpdated(reserveFund, newReserveFund);
        reserveFund = newReserveFund;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    modifier whenNotPaused() {
        if (PausableUpgradeable(address(_getgNFTAddress().SEGMENT_MANAGEMENT())).paused()) {
            revert Paused();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!IAuth(address(_getgNFTAddress().SEGMENT_MANAGEMENT())).isAdmin(msg.sender)) {
            revert Auth();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}
