// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IGoldenExp.sol";

// Libraries
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Contracts
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

contract GoldenStakingRewards is
  ReentrancyGuard,
  Ownable,
  Pausable
{
  using SafeERC20 for IERC20;
  //A SAFEWARD FOR IGoldenExp!!!!????????????????????????????????


  /* ========== STATE VARIABLES ========== */

  IGoldenExp public rewardToken;
  IERC20 public stakingToken;

  uint256 public boost;
  uint256 public periodFinish;
  uint256 public boostedFinish;
  uint256 public rewardRate;
  uint256 public rewardDuration;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 public boostedTimePeriod;
  uint256 public tokenDecimals;
  uint256 private _totalSupply;
  uint256 private stakerCount;
  
  mapping(address => bool) private hasStaked;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewardEarned;
  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _rewardToken,
    address _stakingToken,
    uint256 _rewardsDuration,
    uint256 _boostedTimePeriod,
    uint256 _boost,
    uint256 _decimals // Añadir este nuevo parámetro
  ) {
    rewardToken = IGoldenExp(_rewardToken);
    stakingToken = IERC20(_stakingToken);
    rewardDuration = _rewardsDuration;
    boostedTimePeriod = _boostedTimePeriod;
    boost = _boost;
    tokenDecimals = 10 ** _decimals; // Inicializar los decimales como potencia de 10
  }

  /* ========== VIEWS ========== */

  /// @notice Returns the total balance of the staking token in the contract
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /// @notice Returns the decimals of the token
  function getTokenDecimals() public view returns (uint256) {
      return tokenDecimals;
  }

  /// @notice Returns the timestamp at which the boost period will end
  function getBoostedFinishTime() public view returns (uint256) {
      return boostedFinish;
  }

/// @notice Returns the timestamp at which the rewards period will end
  function getPeriodFinishTime() public view returns (uint256) {
      return periodFinish;
  }

  /// @notice Returns a users deposit of the staking token in the contract
  /// @param account address of the account
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /// @notice Returns the address of the reward token
  function getRewardTokenAddress() external view returns (address) {
      return address(rewardToken);
  }

  /// @notice Returns the last time when a reward was applicable
  function lastTimeRewardApplicable() public view returns (uint256) {
    uint256 timeApp = Math.min(block.timestamp, periodFinish);
    return timeApp;
  }

    /// @notice Devuelve el valor del boost, el número de stakers y el total supply
  function getBoostStakerCount() external view returns (uint256, uint256) {
      return (boost, stakerCount);
  }

  /// @notice Returns the reward per staking token
  function rewardPerToken() public view returns (uint256 perTokenRate) {
    if (_totalSupply == 0) {
      perTokenRate = rewardPerTokenStored;
      return perTokenRate;
    }

    uint256 timeRewardApp = lastTimeRewardApplicable();
    uint256 timeDifference = timeRewardApp > lastUpdateTime ? timeRewardApp - lastUpdateTime : 0;

    if (block.timestamp < boostedFinish) {
      perTokenRate = rewardPerTokenStored + (
        timeDifference
          * rewardRate * boost
          * tokenDecimals
          / _totalSupply
      );
      return perTokenRate;
    } else {
      if (lastUpdateTime < boostedFinish) {
        uint256 normalPeriod = timeRewardApp > boostedFinish ? timeRewardApp - boostedFinish : 0;
        perTokenRate = rewardPerTokenStored 
        + (
            (boostedFinish - lastUpdateTime)
              * rewardRate * boost
              * tokenDecimals
              / _totalSupply
          )
        + (
            (normalPeriod)
              * rewardRate
              * tokenDecimals
              / _totalSupply
          );
        return perTokenRate;
      } else {
        perTokenRate = rewardPerTokenStored + (
          (timeDifference)
            * rewardRate
            * tokenDecimals
            / _totalSupply
        );
        return perTokenRate;
      }
    }
  }

  /// @notice Returns the amount of rewards earned by an account
  /// @param account address of the account
  function earned(address account) public view returns (uint256 tokensEarned) {
    uint256 perTokenRate = rewardPerToken();
    tokensEarned = (_balances[account]
      * (perTokenRate - userRewardPerTokenPaid[account])
      / tokenDecimals)
      + rewardEarned[account];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /// @notice Allows to stake the staking token into the contract for rewards
  /// @param amount amount of staking token to stake
  function stake(uint256 amount)
    external
    whenNotPaused
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, "Cannot stake 0");
    _totalSupply = _totalSupply + amount;
    _balances[msg.sender] = _balances[msg.sender] + amount;
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);

    // If this is the first time the address is staking, increment the counter
    if (!hasStaked[msg.sender]) {
        hasStaked[msg.sender] = true;
        stakerCount++;
    }
  }

  /// @notice Allows to unstake the staking token from the contract
  /// @param amount amount of staking token to unstake
  function unstake(uint256 amount)
    public
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, "Cannot withdraw 0");
    require(amount <= _balances[msg.sender], "Insufficent balance");
    _totalSupply = _totalSupply - amount;
    _balances[msg.sender] = _balances[msg.sender] - amount;
    stakingToken.safeTransfer(msg.sender, amount);
    emit Unstaked(msg.sender, amount);

    // If the address withdraws all its stake, reduce the counter
    if (_balances[msg.sender] == 0 && hasStaked[msg.sender]) {
        hasStaked[msg.sender] = false;
        stakerCount--;
    }
  }

  /// @notice Allows to claim rewards from the contract for staking
  function claim() public whenNotPaused nonReentrant updateReward(msg.sender) {
    uint256 _rewardEarned = rewardEarned[msg.sender];
    if (_rewardEarned > 0) {
      rewardEarned[msg.sender] = 0;
      rewardToken.mint(msg.sender, _rewardEarned);
    }

    emit RewardPaid(msg.sender, _rewardEarned);
  }

  /// @notice Allows to exit the contract by unstaking all staked tokens and claiming rewards
  function exit() external {
    unstake(_balances[msg.sender]);
    claim();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /// @notice Start a new reward period by sending rewards
  /// @dev Can only be called by the owner
  /// @param rewardAmount the amount of rewards to be distributed
  function notifyRewardAmount(uint256 rewardAmount)
    external
    updateReward(address(0))
    onlyOwner
    {
    require(rewardDuration > 0, "rewardDuration_ERROR");

    if (block.timestamp >= periodFinish) {
      rewardRate = rewardAmount / (rewardDuration + boostedTimePeriod);
      boostedFinish = block.timestamp + boostedTimePeriod;
    } else {
      uint256 remaining = periodFinish - block.timestamp;
      uint256 leftoverReward = remaining * rewardRate;
      rewardRate = (rewardAmount + leftoverReward) / rewardDuration;
    }

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp + rewardDuration;

    emit RewardAdded(rewardAmount);
  }

  /// @notice Update the rewards duration
  /// @dev Can only be called by the owner
  /// @param _rewardDuration the rewards duration
  function updateRewardDuration(uint256 _rewardDuration) external onlyOwner {
    rewardDuration = _rewardDuration;

    emit RewardDurationUpdated(_rewardDuration);
  }

  /// @notice Update the boosted time period
  /// @dev Can only be called by the owner
  /// @param _boostedTimePeriod the boosted time period
  function updateBoostedTimePeriod(uint256 _boostedTimePeriod)
    external
    onlyOwner
  {
    boostedTimePeriod = _boostedTimePeriod;

    emit BoostedTimePeriodUpdated(_boostedTimePeriod);
  }

  /// @notice Update the boost
  /// @dev Can only be called by the owner
  /// @param _boost the boost
  function updateBoost(uint256 _boost) external onlyOwner {
    boost = _boost;

    emit BoostUpdated(_boost);
  }

/// @notice Allows the owner to change the reward token
/// @dev Only the owner can call this function
/// @param newRewardToken The address of the new reward token
  function updateRewardToken(address newRewardToken) external onlyOwner {
      require(newRewardToken != address(0), "Invalid token address");
      rewardToken = IGoldenExp(newRewardToken);

      emit RewardTokenUpdated(newRewardToken);
  }


  /// @notice Pauses the contract
  /// @dev Can only be called by the owner
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice Unpauses the contract
  /// @dev Can only be called by the owner
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice this updates the rewards 
  function refreshReward(address _account) external updateReward(_account) {}


  /* ========== MODIFIERS ========== */

  // Modifier *Update Reward modifier*
  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewardEarned[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== EVENTS ========== */

//  event EmergencyWithdraw(address sender);
  event RewardDurationUpdated(uint256 rewardDuration);
  event BoostedTimePeriodUpdated(uint256 boostedTimePeriod);
  event BoostUpdated(uint256 boost);
  event RewardAdded(uint256 rewardAmount);
  event Staked(address indexed user, uint256 amount);
  event Unstaked(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardTokenUpdated(address newRewardToken);
}
