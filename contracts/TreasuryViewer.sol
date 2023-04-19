// SPDX-License-Identifier: UNLICENSED

import "./interfaces/ITreasuryViewer.sol";

pragma solidity ^0.8.4;

contract TreasuryViewer is ITreasuryViewer {
    function rewardSingleMarket(
        uint256 tokenId,
        uint8 tokenWeight,
        address market,
        address underlying,
        ITreasury treasury
    ) public view returns (uint256) {
        if (!treasury.registeredTokenIds(tokenId)) return 0;

        uint256 reserveBPSStored = treasury.reserveBPS();
        address reserveFundStored = treasury.reserveFund();

        uint256 reservesStored = _accrueInterest(ICToken(market));
        uint256 rewards = reservesStored +
            ICToken(underlying).balanceOf(address(treasury)) -
            treasury.rewardBalance(underlying);

        if (reserveFundStored != address(0) && reserveBPSStored > 0) {
            rewards = rewards - (rewards * reserveBPSStored) / 1e4;
        }

        uint256 pendingPart = (tokenWeight *
            (treasury.rewardPerShare(underlying) +
                (rewards * 1e12) /
                treasury.totalRegisteredWeight() -
                treasury.lastClaimForTokenId(underlying, tokenId))) / 1e12;

        return treasury.fixedRewardPayments(underlying, tokenId) + pendingPart;
    }

    function rewardSingleIdWithEvaluation(
        uint256 tokenId,
        uint8 tokenWeight,
        address[] memory markets,
        address[] memory underlying,
        uint8[] memory decimals,
        IOracle oracle,
        ITreasury treasury
    ) public view returns (uint256) {
        uint256 totalReward;
        uint256 factor;
        for (uint256 i; i < markets.length; ) {
            uint256 rewardMarket = rewardSingleMarket(
                tokenId,
                tokenWeight,
                markets[i],
                underlying[i],
                treasury
            );
            factor = 10**(36 - decimals[i]);
            totalReward += oracle.getUnderlyingPrice(markets[i]) * rewardMarket / factor;
            unchecked {
                i++;
            }
        }
        return totalReward;
    }

    function rewardMultipleIdsWithEvaluation(
        uint256[] calldata tokenIds,
        ITreasury treasury
    ) external view returns (uint256[] memory) {
        address[] memory markets = treasury.TONPOUND_COMPTROLLER().getAllMarkets();
        address[] memory underlying = new address[](markets.length);
        uint8[] memory decimals = new uint8[](markets.length);
        uint256[] memory rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < markets.length; ) {
            underlying[i] = ICToken(markets[i]).underlying();
            decimals[i] = ICToken(underlying[i]).decimals();
            unchecked {
                i++;
            }
        }

        IOracle oracle = IOracle(treasury.TONPOUND_COMPTROLLER().oracle());
        IgNFT gNFT = IgNFT(treasury.TONPOUND_COMPTROLLER().gNFT());
        for (uint256 i; i < tokenIds.length; i++) {
            rewards[i] = rewardSingleIdWithEvaluation(
                tokenIds[i],
                gNFT.getTokenSlot0(tokenIds[i]).rewardWeight,
                markets,
                underlying,
                decimals,
                oracle,
                treasury
            );
        }

        return rewards;
    }

    function _accrueInterest(ICToken market) internal view returns (uint256) {
        uint256 reservesStored = market.totalReserves();
        uint256 blockNumberStored = market.accrualBlockNumber();
        if (block.number > blockNumberStored) {
            uint256 cashStored = market.getCash();
            uint256 borrowsStored = market.totalBorrows();
            uint256 reserveFactorMantissa = market.reserveFactorMantissa();

            IInterestRateModel interestRateModel = IInterestRateModel(market.interestRateModel());
            uint256 borrowRateMantissa = interestRateModel.getBorrowRate(
                cashStored,
                borrowsStored,
                reservesStored
            );

            uint256 blockDelta = block.number - blockNumberStored;
            uint256 simpleInterestFactor = borrowRateMantissa * blockDelta;
            uint256 interestAccumulated = (simpleInterestFactor * borrowsStored) / 1e18;
            reservesStored = reservesStored + (reserveFactorMantissa * interestAccumulated) / 1e18;
        }
        return reservesStored;
    }
}
