// SPDX-License-Identifier: UNLICENSED

import "../Treasury.sol";

pragma solidity 0.8.17;

contract TreasuryMockV2 is Treasury {
    function version() external pure returns (uint8) {
        return 2;
    }
}
