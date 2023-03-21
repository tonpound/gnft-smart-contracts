// SPDX-License-Identifier: UNLICENSED

import "../Treasury.sol";

pragma solidity 0.8.17;

contract TreasuryMockV1 is Treasury {
    function version() external pure returns (uint8) {
        return 1;
    }
}
