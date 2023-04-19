// SPDX-License-Identifier: UNLICENSED

import "./IComptroller.sol";
import "./IgNFT.sol";
import "./IAuth.sol";

pragma solidity ^0.8.4;

/// @title  Interface for Tonpound Treasury contract, which is a part of gNFT token
/// @notice Authorization model is based on AccessControl and Pausable contracts from OpenZeppelin:
///         (https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl) and
///         (https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
///         Blacklisting implemented with BLACKLISTED_ROLE, managed by MANAGER_ROLE
interface ITreasury {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason claiming rewards before start of claiming period
    error ClaimingNotStarted();

    /// @notice Revert reason claiming unregistered reward token
    error InvalidRewardToken();

    /// @notice Revert reason for distributing rewards in unsupported reward token
    error InvalidMarket();

    /// @notice Revert reason for setting too high parameter value
    error InvalidParameter();

    /// @notice Revert reason for claiming reward for not-owned gNFT token
    error InvalidTokenOwnership();

    /// @notice Revert reason for accessing protected functions during pause
    error Paused();

    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice Emitted in governance function when reserveBPS variable is updated
    event ReserveFactorUpdated(uint256 oldValue, uint256 newValue);

    /// @notice Emitted in governance function when reserveFund variable is updated
    event ReserveFundUpdated(address oldValue, address newValue);

    /// @notice             View method to read 'fixedRewardPayments' mapping of
    ///                     solid reward payments for tokenId
    /// @param rewardToken  Address of reward token to read mapping for
    /// @param tokenId      gNFT tokenId to read mapping for
    /// @return             Stored bool value of 'fixedRewardPayments[rewardToken][tokenId], 
    ///                     that can be claimed regardless of tokenId registration status
    function fixedRewardPayments(address rewardToken, uint256 tokenId) external view returns (uint256);

    /// @notice             View method to read all supported reward tokens
    /// @return             Array of addresses of registered reward tokens
    function getRewardTokens() external view returns (address[] memory);

    /// @notice             View method to read number of supported reward tokens
    /// @return             Number of registered reward tokens
    function getRewardTokensLength() external view returns (uint256);

    /// @notice             View method to read a single reward token address
    /// @param index        Index of reward token in array to return
    /// @return             Address of reward token at given index in array
    function getRewardTokensAtIndex(uint256 index) external view returns (address);

    /// @notice             View method to read 'lastClaimForTokenId' mapping
    ///                     storing 'rewardPerShare' parameter for 'tokenId'
    ///                     from time of registration or last claiming event
    /// @param rewardToken  Address of reward token to read mapping for
    /// @param tokenId      gNFT tokenId to read mapping for
    /// @return             Stored value of 'lastClaimForTokenId[rewardToken][tokenId]',
    ///                     last claim value of reward per share multiplied by REWARD_PER_SHARE_MULTIPLIER = 1e12
    function lastClaimForTokenId(
        address rewardToken,
        uint256 tokenId
    ) external view returns (uint256);

    /// @notice             View method to get pending rewards for given
    ///                     reward token and gNFT token, contains fixed part for
    ///                     de-registered tokens and calculated part of distributed rewards
    /// @param rewardToken  Address of reward token to calculate pending rewards
    /// @param tokenId      gNFT tokenId to calculate pending rewards for
    /// @return             Value of rewards in rewardToken that would be claimed if claim is available
    function pendingReward(address rewardToken, uint256 tokenId) external view returns (uint256);

    /// @notice             View method to read 'registeredTokenIds' mapping of
    ///                     tracked registered gNFT tokens
    /// @param tokenId      tokenId of gNFT token to read
    /// @return             Stored bool value of 'registeredTokenIds[tokenId]', true if registered
    function registeredTokenIds(uint256 tokenId) external view returns (bool);

    /// @notice             View method to read reserve factor
    /// @return             Fraction (in bps) of rewards going to reserves, can be set to 0
    function reserveBPS() external view returns (uint256);

    /// @notice             View method to read address of reserve fund
    /// @return             Address to collect reserved part of rewards, can be set to 0
    function reserveFund() external view returns (address);

    /// @notice             View method to read 'rewardPerShare' mapping of
    ///                     tracked balances of Treasury contract to properly distribute rewards
    /// @param rewardToken  Address of reward token to read mapping for
    /// @return             Stored value of 'rewardPerShare[rewardToken]',
    ///                     reward per share multiplied by REWARD_PER_SHARE_MULTIPLIER = 1e12
    function rewardPerShare(address rewardToken) external view returns (uint256);

    /// @notice             View method to read 'rewardBalance' mapping of distributed rewards
    ///                     in specified rewardToken stored to properly account fresh rewards
    /// @param rewardToken  Address of reward token to read mapping for
    /// @return             Stored value of 'rewardBalance[rewardToken]'
    function rewardBalance(address rewardToken) external view returns (uint256);

    /// @notice             View method to get the remaining time until start of claiming period
    /// @return             Seconds until claiming is available, zero if claiming has started
    function rewardsClaimRemaining() external view returns (uint256);

    /// @notice             View method to read Tonpound Comptroller address
    /// @return             Address of Tonpound Comptroller contract
    function TONPOUND_COMPTROLLER() external view returns (IComptroller);

    /// @notice             View method to read total weight of registered gNFT tokens,
    ///                     eligible for rewards distribution
    /// @return             Stored value of 'totalRegisteredWeight'
    function totalRegisteredWeight() external view returns (uint256);

    /// @notice             Register and distribute incoming rewards in form of all tokens
    ///                     supported by the Tonpound Comptroller contract
    ///                     Rewards must be re-distributed if there's no users to receive at the moment
    function distributeRewards() external;

    /// @notice             Register and distribute incoming rewards in form of underlying of 'market'
    ///                     Market address must be listed in the Tonpound Comptroller
    ///                     Rewards must be re-distributed if there's no users to receive at the moment
    /// @param market       Address of market cToken to try to distribute
    function distributeReward(address market) external;

    /// @notice             Claim all supported pending rewards for given gNFT token
    ///                     Claimable only after rewardsClaimRemaining() == 0 and
    ///                     only by the owner of given tokenId
    /// @param tokenId      gNFT tokenId to claim rewards for
    function claimRewards(uint256 tokenId) external;

    /// @notice             Claim pending rewards for given gNFT token in form of single 'rewardToken'
    ///                     Claimable only after rewardsClaimRemaining() == 0 and
    ///                     only by the owner of given tokenId
    /// @param tokenId      gNFT tokenId to claim rewards for
    /// @param rewardToken  Address of reward token to claim rewards in
    function claimReward(uint256 tokenId, address rewardToken) external;

    /// @notice             Register or de-register tokenId for rewards distribution
    ///                     De-registering saves acquired rewards in fixed part for claiming when available
    ///                     Restricted for gNFT contract only
    /// @param tokenId      gNFT tokenId to update registration status for
    /// @param state        New boolean registration status
    function registerTokenId(uint256 tokenId, bool state) external;

    /// @notice             Updating reserveBPS factor for reserve fund part of rewards
    /// @param newFactor    New value to be less than 5000
    function setReserveFactor(uint256 newFactor) external;

    /// @notice             Updating reserve fund address
    /// @param newFund      New address to receive future reserve rewards
    function setReserveFund(address newFund) external;

    struct RewardInfo {
        address market;
        uint256 amount;
    }
}
