// SPDX-License-Identifier: UNLICENSED

import "../Constants.sol";

pragma solidity 0.8.17;

contract ConstantsMock {
    function row1() internal pure returns (bytes memory) {
        return
            bytes.concat(
                bytes1(Constants.VOTE_WEIGHT_TOPAZ),
                bytes1(Constants.VOTE_WEIGHT_EMERALD),
                bytes1(Constants.VOTE_WEIGHT_DIAMOND)
            );
    }

    function row2() internal pure returns (bytes memory) {
        return
            bytes.concat(
                bytes1(Constants.REWARD_WEIGHT_TOPAZ),
                bytes1(Constants.REWARD_WEIGHT_EMERALD),
                bytes1(Constants.REWARD_WEIGHT_DIAMOND)
            );
    }

    function row3() internal pure returns (bytes memory) {
        return
            bytes.concat(
                bytes1(Constants.LIQUIDITY_FOR_MINTING_TOPAZ),
                bytes1(Constants.LIQUIDITY_FOR_MINTING_EMERALD),
                bytes1(Constants.LIQUIDITY_FOR_MINTING_DIAMOND)
            );
    }

    function row4() internal pure returns (bytes memory) {
        return
            bytes.concat(
                bytes1(Constants.ACTIVATION_TOPAZ_NOMINATOR),
                bytes1(Constants.ACTIVATION_EMERALD_NOMINATOR),
                bytes1(Constants.ACTIVATION_DIAMOND_NOMINATOR)
            );
    }

    function row5() internal pure returns (bytes memory) {
        return
            bytes.concat(
                bytes1(Constants.LIQUIDITY_FOR_REWARDS_TOPAZ),
                bytes1(Constants.LIQUIDITY_FOR_REWARDS_EMERALD),
                bytes1(Constants.LIQUIDITY_FOR_REWARDS_DIAMOND)
            );
    }

    function row6() internal pure returns (bytes memory) {
        return
            bytes.concat(
                bytes1(Constants.REQUIRE_TOPAZES_FOR_TOPAZ),
                bytes1(Constants.REQUIRE_TOPAZES_FOR_EMERALD),
                bytes1(Constants.REQUIRE_TOPAZES_FOR_DIAMOND)
            );
    }

    function row7() internal pure returns (bytes memory) {
        return
            bytes.concat(
                bytes1(Constants.REQUIRE_EMERALDS_FOR_TOPAZ),
                bytes1(Constants.REQUIRE_EMERALDS_FOR_EMERALD),
                bytes1(Constants.REQUIRE_EMERALDS_FOR_DIAMOND)
            );
    }

    function row8() internal pure returns (bytes memory) {
        return
            bytes.concat(
                bytes1(Constants.REQUIRE_DIAMONDS_FOR_TOPAZ),
                bytes1(Constants.REQUIRE_DIAMONDS_FOR_EMERALD),
                bytes1(Constants.REQUIRE_DIAMONDS_FOR_DIAMOND)
            );
    }

    function concatM() public pure returns (bytes memory) {
        return bytes.concat(row1(), row2(), row3(), row4(), row5(), row6(), row7(), row8());
    }

    function read1(uint256 gem, uint256 group) public view returns (uint8) {
        return uint8(concatM()[group * 3 + gem]);
    }

    function read2(uint256 gem, uint256 group) internal pure returns (uint8) {
        return uint8(Constants.M[group * 3 + gem]);
    }

    function compare() external view returns (bool) {
        for (uint256 i; i < 3; i++) {
            for (uint256 j; j < 8; j++) {
                if (read1(i, j) != read2(i, j)) {
                    return false;
                }
            }
        }
        return true;
    }
}
