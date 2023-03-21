// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721VotesUpgradeable.sol";
import "./interfaces/IERC721Permit.sol";

abstract contract ERC721Permit is
    ERC721EnumerableUpgradeable,
    ERC721VotesUpgradeable,
    IERC721Permit
{
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 expiry)");

    function __ERC721Permit_init(
        string memory name_,
        string memory symbol_,
        string memory version_
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __EIP712_init(name_, version_);
    }

    function permit(
        address spender,
        uint256 tokenId,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > expiry) revert PermitSignatureExpired();
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonce, expiry))
            ),
            v,
            r,
            s
        );
        if (signer != _ownerOf(tokenId)) revert PermitInvalidSignature();
        if (nonce != _useNonce(signer)) revert PermitInvalidNonce();
        _approve(spender, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721VotesUpgradeable, ERC721Upgradeable) {
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
