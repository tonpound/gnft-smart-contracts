// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ISegmentManagement.sol";

/// @title  gNFT governance token for Tonpound protocol
/// @notice Built on ERC721Votes extension from OpenZeppelin Upgradeable library
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Votes)
///         Supports Permit approvals (see IERC721Permit.sol) and Multicall
///         (https://docs.openzeppelin.com/contracts/4.x/api/utils#Multicall)
interface IgNFT {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason for protected functions being called by blacklisted address
    error BlacklistedUser(address account);

    /// @notice Revert reason for accessing protected functions during pause
    error Paused();

    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice              Emitted during minting
    /// @param tokenId       tokenId of minted token
    /// @param data          Metadata of minted token
    event MintData(uint256 tokenId, TokenData data);

    /// @notice              Emitted during slot0 of metadata updating
    /// @param tokenId       tokenId of updated token
    /// @param data          New Slot0 of metadata of updated token
    event UpdatedTokenDataSlot0(uint256 tokenId, Slot0 data);

    /// @notice              Emitted during slot1 of metadata updating
    /// @param tokenId       tokenId of updated token
    /// @param data          New Slot1 of metadata of updated token
    event UpdatedTokenDataSlot1(uint256 tokenId, Slot1 data);

    /// @notice              View method to read SegmentManagement contract address
    /// @return              Address of SegmentManagement contract
    function SEGMENT_MANAGEMENT() external view returns (ISegmentManagement);

    /// @notice               View method to get total vote weight of minted tokens,
    ///                       only gNFTs with fully activated segments participates in the voting
    /// @return               Value of Votes._getTotalSupply(), i.e. latest total checkpoints
    function getTotalVotePower() external view returns (uint256);

    /// @notice               View method to read 'tokenDataById' mapping of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId]' of IgNFT.TokenData type
    function getTokenData(uint256 tokenId) external view returns (TokenData memory);

    /// @notice               View method to read first slot of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId].slot0' of IgNFT.Slot0 type
    function getTokenSlot0(uint256 tokenId) external view returns (Slot0 memory);

    /// @notice               View method to read second slot of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId].slot1' of IgNFT.Slot1 type
    function getTokenSlot1(uint256 tokenId) external view returns (Slot1 memory);

    /// @notice               Minting new gNFT token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param to             Address of recipient
    /// @param data           Parameters of new token to be minted
    function mint(address to, TokenData memory data) external;

    /// @notice               Update IgNFT.Slot0 parameters of IgNFT.TokenData of a token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param tokenId        Token to be updated
    /// @param data           Slot0 structure to update existed
    function updateTokenDataSlot0(uint256 tokenId, Slot0 memory data) external;

    /// @notice               Update IgNFT.Slot1 parameters of IgNFT.TokenData of a token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param tokenId        Token to be updated
    /// @param data           Slot1 structure to update existed
    function updateTokenDataSlot1(uint256 tokenId, Slot1 memory data) external;

    struct TokenData {
        Slot0 slot0;
        Slot1 slot1;
    }

    struct Slot0 {
        TokenType tokenType;
        uint8 activeSegment;
        uint8 voteWeight;
        uint8 rewardWeight;
        bool usedForMint;
        uint48 completionTimestamp;
        address lockedMarket;
    }

    struct Slot1 {
        uint256 lockedVaultShares;
    }

    enum TokenType {
        Topaz,
        Emerald,
        Diamond
    }
}
