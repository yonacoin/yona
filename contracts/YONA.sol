// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract YONA is ERC20, ReentrancyGuard {
    // Owners
    address public owner1;
    address public owner2;

    // Minting Caps
    uint256 public immutable totalMintCap;
    uint256 public immutable yearlyMintCap;

    // Initial Supply
    uint256 public immutable initialSupply;

    // Staking Parameters
    uint256 public startTime;

    // Minted tokens tracking per year
    mapping(uint256 => uint256) public mintedPerYear;

    // Staking Plan Types
    enum StakingType { Flexible, Hard }

    // Staking Plan Structure
    struct StakingPlan {
        uint256 rewardRate;      // Annual reward rate in basis points (e.g., 1000 for 10%)
        uint256 duration;        // Duration in seconds for Hard staking; 0 for Flexible
        StakingType stakingType; // Type of staking: Flexible or Hard
        bool exists;             // Plan existence flag
        uint256 totalStaked;     // Total amount staked under this plan
    }

    // User's Staking Information
    struct StakingInfo {
        uint256 amount;
        uint256 startTime;
        uint256 planId;
    }

    // Mappings
    mapping(address => StakingInfo) public stakingBalances;
    mapping(uint256 => StakingPlan) public stakingPlans;

    // Plan tracking
    uint256 public planCount;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 planId);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event PlanAdded(uint256 indexed planId, uint256 rewardRate, uint256 duration, StakingType stakingType);
    event PlanUpdated(uint256 indexed planId, uint256 rewardRate, uint256 duration, StakingType stakingType);
    event OwnershipTransferred(address indexed previousOwner1, address indexed newOwner1, address previousOwner2, address newOwner2);
    event RewardScaled(uint256 planId, uint256 newRewardRate);

    // Modifiers
    modifier onlyOwners() {
        require(msg.sender == owner1 || msg.sender == owner2, "Not an owner");
        _;
    }

    /**
     * @dev Constructor initializes the token with the given parameters.
     * @param _initialSupply The initial supply of the token.
     * @param _owner2 The address of the second owner.
     */
    constructor(
        uint256 _initialSupply,
        address _owner2
    ) ERC20("YONA", "YONA") {
        require(_owner2 != address(0), "Owner2 address cannot be zero");
        require(msg.sender != _owner2, "Owner1 and Owner2 cannot be the same");

        owner1 = msg.sender;
        owner2 = _owner2;
        initialSupply = _initialSupply;
        totalMintCap = _initialSupply;
        yearlyMintCap = totalMintCap / 10; // 10% of totalMintCap

        startTime = block.timestamp;

        // Distribute initial supply equally to both owners
        _mint(owner1, initialSupply / 2);
        _mint(owner2, initialSupply / 2);
    }

    /**
     * @dev Transfers ownership to new owners. Ensures newOwner1 and newOwner2 are different.
     * @param newOwner1 The address of the new first owner.
     * @param newOwner2 The address of the new second owner.
     */
    function transferOwnership(address newOwner1, address newOwner2) external onlyOwners {
        require(newOwner1 != address(0) && newOwner2 != address(0), "New owners cannot be zero address");
        require(newOwner1 != newOwner2, "Owners must be different addresses");

        emit OwnershipTransferred(owner1, newOwner1, owner2, newOwner2);

        owner1 = newOwner1;
        owner2 = newOwner2;
    }

    /**
     * @dev Adds a new staking plan with a unique planId. Increments planCount internally.
     * @param rewardRate The annual reward rate in basis points (e.g., 1000 for 10%).
     * @param duration The staking duration in seconds. Set to 0 for Flexible staking.
     * @param stakingType The type of staking: Flexible or Hard.
     */
    function addStakingPlan(
        uint256 rewardRate,
        uint256 duration,
        StakingType stakingType
    ) external onlyOwners {
        uint256 planId = ++planCount;
        stakingPlans[planId] = StakingPlan({
            rewardRate: rewardRate,
            duration: duration,
            stakingType: stakingType,
            exists: true,
            totalStaked: 0
        });
        emit PlanAdded(planId, rewardRate, duration, stakingType);
    }

    /**
     * @dev Updates an existing staking plan. Can only update if no active stakes exist under the plan.
     * @param planId The ID of the staking plan to update.
     * @param rewardRate The new annual reward rate in basis points.
     * @param duration The new staking duration in seconds.
     * @param stakingType The new type of staking: Flexible or Hard.
     */
    function updateStakingPlan(
        uint256 planId,
        uint256 rewardRate,
        uint256 duration,
        StakingType stakingType
    ) external onlyOwners {
        StakingPlan storage plan = stakingPlans[planId];
        require(plan.exists, "Plan does not exist");
        require(plan.totalStaked == 0, "Active stakes exist under this plan");

        plan.rewardRate = rewardRate;
        plan.duration = duration;
        plan.stakingType = stakingType;

        emit PlanUpdated(planId, rewardRate, duration, stakingType);
    }

    /**
     * @dev Allows users to stake their tokens with a selected plan.
     * @param amount The amount of tokens to stake.
     * @param planId The ID of the staking plan to use.
     */
    function stake(uint256 amount, uint256 planId) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        StakingPlan storage plan = stakingPlans[planId];
        require(plan.exists, "Invalid staking plan");

        StakingInfo storage userStake = stakingBalances[msg.sender];
        require(userStake.amount == 0, "Already staking");

        // For Flexible staking, enforce a minimum staking duration to prevent abuse
        if (plan.stakingType == StakingType.Flexible) {
            require(plan.duration >= 1 days, "Flexible staking must have a minimum duration of 1 day");
        }

        userStake.amount = amount;
        userStake.startTime = block.timestamp;
        userStake.planId = planId;

        plan.totalStaked += amount;

        _transfer(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, planId);
    }

    /**
     * @dev Allows users to unstake their tokens and claim rewards.
     */
    function unstake() external nonReentrant {
        StakingInfo storage userStake = stakingBalances[msg.sender];
        require(userStake.amount > 0, "No active stake");

        uint256 planId = userStake.planId;
        StakingPlan storage plan = stakingPlans[planId];

        uint256 stakedTime = block.timestamp - userStake.startTime;
        uint256 reward;

        if (plan.stakingType == StakingType.Hard) {
            require(block.timestamp >= userStake.startTime + plan.duration, "Staking duration not met");
            reward = calculateReward(userStake.amount, plan.rewardRate, plan.duration);
        } else {
            // Flexible staking with minimum duration enforced during staking
            reward = calculateReward(userStake.amount, plan.rewardRate, stakedTime);
        }

        uint256 currentYear = (block.timestamp - startTime) / 365 days;
        require(mintedPerYear[currentYear] + reward <= yearlyMintCap, "Yearly mint cap exceeded");

        mintedPerYear[currentYear] += reward;

        plan.totalStaked -= userStake.amount;

        uint256 stakedAmount = userStake.amount;
        delete stakingBalances[msg.sender];

        _mint(msg.sender, reward);
        _transfer(address(this), msg.sender, stakedAmount);

        emit Unstaked(msg.sender, stakedAmount, reward);
    }

    /**
     * @dev Calculates the reward based on amount, rate, and time.
     * @param amount The amount staked.
     * @param rewardRate The annual reward rate in basis points.
     * @param time The time staked in seconds.
     * @return The calculated reward.
     */
    function calculateReward(uint256 amount, uint256 rewardRate, uint256 time) internal pure returns (uint256) {
        return (amount * rewardRate * time) / (365 days * 10000);
    }

    /**
     * @dev Scales the reward rate of a staking plan if the yearly mint cap is nearing.
     * This function can be called periodically (e.g., by a keeper) to adjust reward rates dynamically.
     * @param planId The ID of the staking plan to scale.
     */
    function scaleRewardRate(uint256 planId) external onlyOwners {
        StakingPlan storage plan = stakingPlans[planId];
        require(plan.exists, "Plan does not exist");

        uint256 currentYear = (block.timestamp - startTime) / 365 days;
        uint256 availableMint = yearlyMintCap - mintedPerYear[currentYear];
        if (availableMint < yearlyMintCap) {
            // Example scaling: Reduce reward rate proportionally based on available mint
            uint256 scalingFactor = (availableMint * 10000) / yearlyMintCap;
            uint256 newRewardRate = (plan.rewardRate * scalingFactor) / 10000;
            plan.rewardRate = newRewardRate;
            emit RewardScaled(planId, newRewardRate);
        }
    }

    /**
     * @dev Get the total number of staking plans added.
     * @return The total number of staking plans.
     */
    function getTotalStakingPlans() external view returns (uint256) {
        return planCount;
    }
}