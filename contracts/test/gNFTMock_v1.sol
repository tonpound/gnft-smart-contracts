// SPDX-License-Identifier: UNLICENSED

import "../gNFT.sol";

pragma solidity 0.8.17;

contract gNFTMockV1 is gNFT {
    function _baseURI() internal pure override returns (string memory) {
        return "1-";
    }
}
