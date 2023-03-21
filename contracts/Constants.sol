// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Constants {
    // gNFT constants
    uint8 internal constant VOTE_WEIGHT_TOPAZ = 1;
    uint8 internal constant VOTE_WEIGHT_EMERALD = 11;
    uint8 internal constant VOTE_WEIGHT_DIAMOND = 121;

    uint8 internal constant REWARD_WEIGHT_TOPAZ = 1;
    uint8 internal constant REWARD_WEIGHT_EMERALD = 11;
    uint8 internal constant REWARD_WEIGHT_DIAMOND = 121;

    uint8 internal constant LIQUIDITY_FOR_MINTING_TOPAZ = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_MINTING_EMERALD = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_MINTING_DIAMOND = 1; // mul by EXP_1E20

    uint8 internal constant ACTIVATION_TOPAZ_NOMINATOR = 1;
    uint8 internal constant ACTIVATION_EMERALD_NOMINATOR = 10;
    uint8 internal constant ACTIVATION_DIAMOND_NOMINATOR = 100;

    uint8 internal constant LIQUIDITY_FOR_REWARDS_TOPAZ = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_REWARDS_EMERALD = 0; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_REWARDS_DIAMOND = 0; // mul by EXP_1E20

    uint8 internal constant REQUIRE_TOPAZES_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_TOPAZES_FOR_EMERALD = 10;
    uint8 internal constant REQUIRE_TOPAZES_FOR_DIAMOND = 10;

    uint8 internal constant REQUIRE_EMERALDS_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_EMERALDS_FOR_EMERALD = 0;
    uint8 internal constant REQUIRE_EMERALDS_FOR_DIAMOND = 1;

    uint8 internal constant REQUIRE_DIAMONDS_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_DIAMONDS_FOR_EMERALD = 0;
    uint8 internal constant REQUIRE_DIAMONDS_FOR_DIAMOND = 0;

    uint8 internal constant SEGMENTS_NUMBER = 12;
    uint256 internal constant REWARD_ACCUMULATING_PERIOD = 365 days;
    uint256 internal constant ACTIVATION_MIN_PRICE = 1000e18;
    uint256 internal constant ACTIVATION_DENOMINATOR = 1e3;
    uint256 internal constant AIRDROP_DISCOUNT_NOMINATOR = 0;
    uint256 internal constant AIRDROP_DISCOUNT_DENOMINATOR = 1e6;
    uint256 internal constant EXP_ORACLE = 1e18;
    uint256 internal constant EXP_LIQUIDITY = 1e20;
    string internal constant BASE_URI = "Not supported";

    //@notice uint8 parameters packed into bytes constant
    bytes internal constant M = hex"010b79010b79010101010a64010000000a0a000001000000";

    // Treasury constants
    uint256 internal constant EXP_REWARD_PER_SHARE = 1e12;
    uint256 internal constant REWARD_PER_SHARE_MULTIPLIER = 1e12;
    uint256 internal constant MAX_RESERVE_BPS = 5e3;
    uint256 internal constant DENOM_BPS = 1e4;

    // Common constants
    uint256 internal constant DEFAULT_DECIMALS = 18;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    function TYPE_PARAMETERS(uint256 col, uint256 row) internal pure returns (uint8) {
        unchecked {
            return uint8(M[row * 3 + col]);
        }
    }

    enum ParameterType {
        VoteWeight,
        RewardWeight,
        MintingLiquidity,
        ActivationNominator,
        RewardsLiquidity,
        RequiredTopazes,
        RequiredEmeralds,
        RequiredDiamonds
    }
}
