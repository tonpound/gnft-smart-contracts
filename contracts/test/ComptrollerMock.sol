// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ComptrollerMock {
    address public oracle;
    address public treasury;
    address public gNFT;
    address[] public allMarkets;
    address private TPI;
    mapping(address => address[]) public accountAssets;
    mapping(address => uint256) public compAccrued;

    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
        mapping(address => bool) accountMembership;
        bool isComped;
    }

    mapping(address => Market) public markets;

    function initialize(
        address oracle_,
        address treasury_,
        address gnft_,
        address tpi_
    ) external {
        oracle = oracle_;
        treasury = treasury_;
        gNFT = gnft_;
        TPI = tpi_;
    }

    function supportMarket(address market) external {
        if (markets[market].isListed) revert("Existed");
        Market storage newMarket = markets[market];
        newMarket.isListed = true;
        newMarket.isComped = false;
        newMarket.collateralFactorMantissa = 0;

        for (uint256 i = 0; i < allMarkets.length; i++) {
            require(allMarkets[i] != market, "market already added");
        }
        allMarkets.push(market);
    }

    function enterMarkets(address[] memory marketsToEnter) external {
        uint256 len = marketsToEnter.length;
        for (uint256 i = 0; i < len; i++) {
            markets[marketsToEnter[i]].accountMembership[msg.sender] = true;
            accountAssets[msg.sender].push(marketsToEnter[i]);
        }
    }

    function checkMembership(address account, address market) external view returns (bool) {
        return markets[market].accountMembership[account];
    }

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256 err,
            uint256 liquidity,
            uint256 shortfall
        )
    {
        return (0, 0, 0);
    }

    function getAllMarkets() external view returns (address[] memory) {
        return allMarkets;
    }

    function getAssetsIn(address account) external view returns (address[] memory) {
        address[] memory assetsIn = accountAssets[account];
        return assetsIn;
    }

    function getCompAddress() external view returns (address) {
        return TPI;
    }

    function setCompAccrued(
        address user,
        uint256 amount
    ) external {
        compAccrued[user] = amount;
    }

    function claimComp(
        address[] memory holders,
        address[] memory markets,
        bool bor,
        bool sup
    ) external {
        IERC20 tpi = IERC20(TPI);
        uint256 remaining;
        uint256 amount;
        address user;
        for (uint j = 0; j < holders.length; j++) {
            user = holders[j];
            remaining = tpi.balanceOf(address(this));
            amount = compAccrued[user];
            if (amount > 0 && amount <= remaining) {
                tpi.transfer(user, amount);
                compAccrued[user] = 0;
            }
        }
    }
}
