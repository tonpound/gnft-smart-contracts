// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./Auth.sol";
import "./Constants.sol";
import "./VaultFactory.sol";
import "./interfaces/ISegmentManagement.sol";

pragma solidity 0.8.17;

contract SegmentManagement is
    Auth,
    VaultFactory,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    ISegmentManagement
{
    IgNFT public immutable gNFT;
    IComptroller public immutable TONPOUND_COMPTROLLER;

    uint256 private _totalInactiveSegments;
    bytes32 private _airdropMerkleRoot;

    mapping(bytes32 => bool) private _discountUsed;

    function initialize(address vault_, address manager_, address pauser_) external initializer {
        if (vault_ == address(0)) revert ZeroAddress();
        __Auth_init(manager_, pauser_);
        __VaultFactory_init(vault_);
        __UUPSUpgradeable_init();
    }

    function mint(address[] memory markets) external whenNotPaused nonReentrant {
        _checkLiquidity(markets, IgNFT.TokenType.Topaz);
        _mintInternal(msg.sender, IgNFT.TokenType.Topaz, 0, 0);
    }

    function mint(
        address[] memory markets,
        IgNFT.TokenType tokenType,
        uint256[] calldata proofIds
    ) external whenNotPaused nonReentrant {
        _checkTokenType(tokenType, proofIds);
        _checkLiquidity(markets, tokenType);
        _mintInternal(msg.sender, tokenType, 0, 0);
    }

    function _mintInternal(
        address to,
        IgNFT.TokenType tokenType,
        uint48 completionTimestamp,
        uint8 segments
    ) internal {
        IgNFT.TokenData memory tokenData = IgNFT.TokenData({
            slot0: IgNFT.Slot0({
                tokenType: tokenType,
                activeSegment: segments,
                voteWeight: uint8(_getTypeParameter(tokenType, Constants.ParameterType.VoteWeight)),
                rewardWeight: uint8(
                    _getTypeParameter(tokenType, Constants.ParameterType.RewardWeight)
                ),
                usedForMint: false,
                completionTimestamp: completionTimestamp,
                lockedMarket: address(0)
            }),
            slot1: IgNFT.Slot1({lockedVaultShares: 0})
        });
        _totalInactiveSegments += Constants.SEGMENTS_NUMBER - segments;
        gNFT.mint(to, tokenData);
    }

    function _checkTokenType(IgNFT.TokenType tokenType, uint256[] calldata proofIds) internal {
        IgNFT.Slot0 memory data0;
        uint256 numTopaz;
        uint256 numEmerald;
        uint256 numDiamond;
        uint256 len = proofIds.length;
        uint256 proofId;
        uint256 requiredTopazes = _getTypeParameter(
            tokenType,
            Constants.ParameterType.RequiredTopazes
        );
        uint256 requiredEmeralds = _getTypeParameter(
            tokenType,
            Constants.ParameterType.RequiredEmeralds
        );
        uint256 requiredDiamonds = _getTypeParameter(
            tokenType,
            Constants.ParameterType.RequiredDiamonds
        );

        for (uint256 i; i < len; ) {
            proofId = proofIds[i];
            _requireOwnership(proofId);
            data0 = _getSlot0(proofId);
            if (data0.activeSegment != Constants.SEGMENTS_NUMBER) {
                revert InvalidSegmentsNumber();
            }
            unchecked {
                if (!data0.usedForMint) {
                    bool used = false;
                    if (data0.tokenType == IgNFT.TokenType.Topaz && numTopaz < requiredTopazes) {
                        numTopaz++;
                        used = true;
                    } else if (
                        data0.tokenType == IgNFT.TokenType.Emerald && numEmerald < requiredEmeralds
                    ) {
                        numEmerald++;
                        used = true;
                    } else if (numDiamond < requiredDiamonds) {
                        numDiamond++;
                        used = true;
                    }
                    if (used) {
                        data0.usedForMint = true;
                        _updateSlot0(proofId, data0);
                    }
                }
                i++;
            }
        }
        if (
            numTopaz < requiredTopazes ||
            numEmerald < requiredEmeralds ||
            numDiamond < requiredDiamonds
        ) revert MintingRequirementsNotMet();
    }

    function _checkLiquidity(address[] memory markets, IgNFT.TokenType tokenType) internal {
        IOracle oracle = _getOracle();
        IComptroller comptroller = TONPOUND_COMPTROLLER;
        uint256 liquidityValue = _getTypeParameter(
            tokenType,
            Constants.ParameterType.MintingLiquidity
        );
        uint256 len = markets.length;
        uint256 totalValue;
        address market;
        for (uint256 i; i < len; ) {
            market = markets[i];
            _checkMarketListed(market, comptroller);
            totalValue += _quoteLiquiditySingle(
                market,
                oracle,
                ICToken(market).balanceOf(msg.sender),
                false
            );
            if (totalValue >= liquidityValue) {
                return;
            }
            unchecked {
                i++;
            }
        }
        revert FailedLiquidityCheck();
    }

    function _checkMarketListed(address market, IComptroller comptroller) internal view {
        if (!comptroller.markets(market).isListed) {
            revert InvalidMarket();
        }
    }

    function _quoteLiquiditySingle(
        address market,
        IOracle oracle,
        uint256 amount,
        bool reverse
    ) internal returns (uint256) {
        uint256 eval = oracle.getEvaluation(market, amount, reverse);
        if (eval == 0) revert OracleFailed();
        return eval;
    }

    function getActivationPrice(
        uint256 tokenId,
        uint8 segmentsToOpen,
        bool discounted
    ) external view returns (uint256) {
        IgNFT.Slot0 memory data0 = _getSlot0(tokenId);
        if (Constants.SEGMENTS_NUMBER - data0.activeSegment < segmentsToOpen)
            revert InvalidSegmentsNumber();
        return _getActivationPrice(data0, segmentsToOpen, _totalInactiveSegments, discounted);
    }

    function _getActivationPrice(
        IgNFT.Slot0 memory data0,
        uint8 numberOfSegments,
        uint256 totalInactiveSegments,
        bool discounted
    ) internal view returns (uint256) {
        uint256 avgPrice;
        if (totalInactiveSegments > 0) {
            try TPI().getCirculatingSupply() returns (uint256 supply) {
                avgPrice = supply / totalInactiveSegments;
            } catch {}
        }
        avgPrice = MathUpgradeable.max(avgPrice, Constants.ACTIVATION_MIN_PRICE) * numberOfSegments;
        if (discounted) {
            avgPrice =
                (avgPrice * Constants.AIRDROP_DISCOUNT_NOMINATOR) /
                Constants.AIRDROP_DISCOUNT_DENOMINATOR;
        }
        uint256 typeNominator = _getTypeParameter(
            data0.tokenType,
            Constants.ParameterType.ActivationNominator
        );
        return (avgPrice * typeNominator) / Constants.ACTIVATION_DENOMINATOR;
    }

    function activateSegments(
        uint256 tokenId,
        uint8 segments,
        address market
    ) external whenNotPaused validUser(msg.sender) nonReentrant {
        _requireOwnership(tokenId);
        _activateSegmentsInternal(tokenId, segments, market, msg.sender, false);
    }

    function activateSegmentWithProof(
        uint256 tokenId,
        address account,
        uint256 nonce,
        bytes32[] memory proof,
        address market
    ) external whenNotPaused validUser(account) nonReentrant {
        (bytes32 leaf, bytes32 root) = _validateProof(account, nonce, proof);
        _activateSegmentsInternal(tokenId, 1, market, account, true);
        emit Discounted(leaf, root);
    }

    function _activateSegmentsInternal(
        uint256 tokenId,
        uint8 segments,
        address market,
        address account,
        bool discounted
    ) internal {
        IgNFT.Slot0 memory data0 = _getSlot0(tokenId);
        uint8 availableSegments = Constants.SEGMENTS_NUMBER - data0.activeSegment;
        if (availableSegments == 0) {
            revert AlreadyFullyActivated();
        } else if (segments > availableSegments) {
            revert ExceedingMaxSegments();
        } else if (segments == availableSegments) {
            data0 = _completeSegments(tokenId, data0, market, account);
        }
        uint256 totalInactive = _totalInactiveSegments;
        uint256 activationPrice = _getActivationPrice(data0, segments, totalInactive, discounted);
        uint8 newSegment;
        unchecked {
            newSegment = data0.activeSegment + segments;
            data0.activeSegment = newSegment;
            _totalInactiveSegments = totalInactive - segments;
        }
        _updateSlot0(tokenId, data0);
        TPI().burnFrom(msg.sender, activationPrice);
        emit ActivatedSegments(tokenId, newSegment);
    }

    function _validateProof(
        address account,
        uint256 nonce,
        bytes32[] memory proof
    ) internal returns (bytes32, bytes32) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, nonce))));
        if (_discountUsed[leaf]) revert DiscountUsed();
        _discountUsed[leaf] = true;
        bytes32 root = _airdropMerkleRoot;
        if (!MerkleProofUpgradeable.verify(proof, root, leaf)) revert InvalidProof();
        return (leaf, root);
    }

    function _completeSegments(
        uint256 tokenId,
        IgNFT.Slot0 memory data0,
        address market,
        address account
    ) internal returns (IgNFT.Slot0 memory) {
        if (!_treasuryReleased()) {
            if (market == address(0)) revert MarketForLockNotSpecified();
            uint256 liquidity = _getTypeParameter(
                data0.tokenType,
                Constants.ParameterType.RewardsLiquidity
            );
            (data0) = _lockLiquidityInternal(tokenId, data0, market, account, liquidity);
        }
        _getTreasury().registerTokenId(tokenId, true);
        data0.completionTimestamp = uint48(block.timestamp);
        emit TokenCompleted(tokenId, msg.sender);
        return data0;
    }

    function _treasuryReleased() internal view returns (bool) {
        return _getTreasury().rewardsClaimRemaining() == 0;
    }

    function _lockLiquidityInternal(
        uint256 tokenId,
        IgNFT.Slot0 memory data0,
        address market,
        address account,
        uint256 value
    ) internal returns (IgNFT.Slot0 memory) {
        if (value > 0) {
            uint256 amountToLock = _quoteLiquiditySingle(market, _getOracle(), value, true);
            uint256 vaultShares = _vaultLock(tokenId, market, amountToLock, account);
            data0.lockedMarket = market;
            IgNFT.Slot1 memory data1 = _getSlot1(tokenId);
            data1.lockedVaultShares = vaultShares;
            _updateSlot1(tokenId, data1);
        }
        _getTreasury().registerTokenId(tokenId, true);
        return (data0);
    }

    function lockLiquidity(uint256 tokenId, address market) external whenNotPaused nonReentrant {
        _requireOwnership(tokenId);
        if (!_treasuryReleased()) {
            IgNFT.TokenData memory data = _getTokenData(tokenId);
            if (data.slot1.lockedVaultShares > 0) revert TokenAlreadyLocked();
            if (market == address(0)) revert MarketForLockNotSpecified();
            uint256 liquidity = _getTypeParameter(
                data.slot0.tokenType,
                Constants.ParameterType.RewardsLiquidity
            );
            _lockLiquidityInternal(tokenId, data.slot0, market, msg.sender, liquidity);
        }
        _getTreasury().registerTokenId(tokenId, true);
    }

    function unlockLiquidity(uint256 tokenId) external whenNotPaused nonReentrant {
        _requireOwnership(tokenId);
        ITreasury treasury = _getTreasury();
        if (treasury.rewardsClaimRemaining() > 0) {
            treasury.registerTokenId(tokenId, false);
        }
        _unlockLiquidityInternal(tokenId, msg.sender);
    }

    function _unlockLiquidityInternal(uint256 tokenId, address account) internal {
        IgNFT.Slot0 memory data0 = _getSlot0(tokenId);
        IgNFT.Slot1 memory data1 = _getSlot1(tokenId);
        _vaultUnlock(tokenId, data0.lockedMarket, data1.lockedVaultShares, account);
        data0.lockedMarket = address(0);
        data1.lockedVaultShares = 0;
        _updateSlot0(tokenId, data0);
        _updateSlot1(tokenId, data1);
    }

    function quoteLiquidityForLock(
        address market,
        IgNFT.TokenType tokenType
    ) external view returns (uint256) {
        uint256 liquidity = _getTypeParameter(tokenType, Constants.ParameterType.RewardsLiquidity);
        return _getOracle().getEvaluationStored(market, liquidity, true);
    }

    function _getTokenData(uint256 tokenId) internal view returns (IgNFT.TokenData memory) {
        return gNFT.getTokenData(tokenId);
    }

    function _getSlot0(uint256 tokenId) internal view returns (IgNFT.Slot0 memory) {
        return gNFT.getTokenSlot0(tokenId);
    }

    function _getSlot1(uint256 tokenId) internal view returns (IgNFT.Slot1 memory) {
        return gNFT.getTokenSlot1(tokenId);
    }

    function _updateSlot0(uint256 tokenId, IgNFT.Slot0 memory data) internal {
        gNFT.updateTokenDataSlot0(tokenId, data);
    }

    function _updateSlot1(uint256 tokenId, IgNFT.Slot1 memory data) internal {
        gNFT.updateTokenDataSlot1(tokenId, data);
    }

    function _requireOwnership(uint256 tokenId) internal view {
        if (IERC721Upgradeable(address(gNFT)).ownerOf(tokenId) != msg.sender)
            revert InvalidTokenOwnership(tokenId);
    }

    function _getTypeParameter(
        IgNFT.TokenType col,
        Constants.ParameterType row
    ) internal pure returns (uint256) {
        uint256 param = Constants.TYPE_PARAMETERS(uint256(col), uint256(row));
        if (
            row == Constants.ParameterType.RewardsLiquidity ||
            row == Constants.ParameterType.MintingLiquidity
        ) {
            unchecked {
                param *= Constants.EXP_LIQUIDITY;
            }
        }
        return param;
    }

    function _getOracle() internal view returns (IOracle) {
        return IOracle(TONPOUND_COMPTROLLER.oracle());
    }

    function _getTreasury() internal view returns (ITreasury) {
        return ITreasury(TONPOUND_COMPTROLLER.treasury());
    }

    function TPI() public view override returns (ITPIToken) {
        return ITPIToken(TONPOUND_COMPTROLLER.getCompAddress());
    }

    function setMerkleRoot(bytes32 root) external onlyRole(MANAGER_ROLE) {
        emit AirdropMerkleRootChanged(_airdropMerkleRoot, root);
        _airdropMerkleRoot = root;
    }

    function updateVaultImplementation(
        address implementation
    ) external onlyRole(Constants.DEFAULT_ADMIN_ROLE) {
        _updateImplementation(implementation);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(Constants.DEFAULT_ADMIN_ROLE) {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address gnft_, address comptroller_) VaultFactory() {
        if (gnft_ == address(0) || comptroller_ == address(0))
            revert ZeroAddress();
        TONPOUND_COMPTROLLER = IComptroller(comptroller_);
        gNFT = IgNFT(gnft_);
        _disableInitializers();
    }
}
