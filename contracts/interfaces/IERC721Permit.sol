// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Interface for ERC721Permit extension for signature based approvals
/// @notice Built on ERC721Votes extension from OpenZeppelin library
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Votes)
interface IERC721Permit {
    /// @notice Revert reason for expired deadline for signature
    error PermitSignatureExpired();

    /// @notice Revert reason for recovered signer not equal to the owner of tokenId
    error PermitInvalidSignature();

    /// @notice Revert reason for using a wrong nonce value
    error PermitInvalidNonce();

    /// @notice The permit typehash used in the permit signature, see EIP712
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice         Approve of a specific token ID for spending by spender via signature
    /// @param spender  The account that is being approved
    /// @param tokenId  The ID of the token that is being approved for spending
    /// @param nonce    Current nonce of signer to consume
    /// @param expiry   The deadline timestamp by which the call must be mined for the approve to work
    /// @param v        Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r        Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s        Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
