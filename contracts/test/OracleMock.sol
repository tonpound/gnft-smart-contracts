// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

contract OracleMock {
    mapping(address => uint256) prices;

    function setPrice(address market, uint256 price) external {
        prices[market] = price;
    }

    function getUnderlyingPrice(address market) external view returns (uint256) {
        return prices[market];
    }

    function getEvaluation(address cToken, uint256 amount, bool reverse) public returns (uint256) {
        uint256 price = prices[cToken];     // 1 weth = 1e21
        if (reverse) {
            return amount * 1e18 / price;
        }
        return amount * price / 1e18;
    }

    function getEvaluationStored(
        address cToken,
        uint256 amount,
        bool reverse
    ) external view returns (uint256) {
        uint256 price = prices[cToken];
        if (reverse) {
            return amount * 1e18 / price;
        }
        return amount * price / 1e18;
    }

    function assetPrices(address asset) external view returns (uint256) {
        return prices[asset];
    }
}
