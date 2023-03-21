// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./ERC721Permit.sol";
import "./Constants.sol";
import "./interfaces/IgNFT.sol";
import "./interfaces/IAuth.sol";

pragma solidity 0.8.17;

contract gNFT is ERC721Permit, UUPSUpgradeable, Multicall, IgNFT {
    ISegmentManagement public SEGMENT_MANAGEMENT;

    mapping(uint256 => TokenData) private _tokenDataById;

    function initialize(
        string memory name_,
        string memory symbol_,
        address segmenter_
    ) external initializer {
        if (segmenter_ == address(0)) revert ZeroAddress();
        __ERC721Permit_init(name_, symbol_, "1");
        __UUPSUpgradeable_init();

        SEGMENT_MANAGEMENT = ISegmentManagement(segmenter_);
    }

    function mint(address to, TokenData memory data) external onlySegmentManagement {
        uint256 tokenId = totalSupply();
        _tokenDataById[tokenId] = data;
        emit MintData(tokenId, data);
        super._mint(to, tokenId);
    }

    function updateTokenDataSlot0(
        uint256 tokenId,
        Slot0 memory data
    ) external onlySegmentManagement {
        _tokenDataById[tokenId].slot0 = data;
        emit UpdatedTokenDataSlot0(tokenId, data);
    }

    function updateTokenDataSlot1(
        uint256 tokenId,
        Slot1 memory data
    ) external onlySegmentManagement {
        _tokenDataById[tokenId].slot1 = data;
        emit UpdatedTokenDataSlot1(tokenId, data);
    }

    function getTotalVotePower() external view returns (uint256) {
        return _getTotalSupply();
    }

    function getTokenData(uint256 tokenId) external view returns (TokenData memory) {
        return _tokenDataById[tokenId];
    }

    function getTokenSlot0(uint256 tokenId) external view returns (Slot0 memory) {
        return _tokenDataById[tokenId].slot0;
    }

    function getTokenSlot1(uint256 tokenId) external view returns (Slot1 memory) {
        return _tokenDataById[tokenId].slot1;
    }

    function _baseURI() internal pure virtual override returns (string memory) {
        return Constants.BASE_URI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override whenNotPaused validUser(from) validUser(to) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        uint256 weightedBalance;
        uint256 lastId = firstTokenId + batchSize;
        for (uint256 i = firstTokenId; i < lastId; ) {
            weightedBalance += _tokenDataById[i].slot0.voteWeight;
            unchecked {
                i++;
            }
        }
        super._afterTokenTransfer(from, to, firstTokenId, weightedBalance);
    }

    modifier whenNotPaused() {
        if (PausableUpgradeable(address(SEGMENT_MANAGEMENT)).paused()) revert Paused();
        _;
    }

    modifier validUser(address account) {
        if (!IAuth(address(SEGMENT_MANAGEMENT)).isValidUser(account))
            revert BlacklistedUser(account);
        _;
    }

    modifier onlySegmentManagement() {
        if (msg.sender != address(SEGMENT_MANAGEMENT)) revert Auth();
        _;
    }

    modifier onlyAdmin() {
        if (!IAuth(address(SEGMENT_MANAGEMENT)).isAdmin(msg.sender)) revert Auth();
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}
