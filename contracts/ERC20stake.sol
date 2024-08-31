// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking is Ownable {
    using SafeMath for uint256;

    IERC20 public stakingToken; // The ERC20 token to stake
    uint256 public rewardRate = 100; // Reward rate per second (for simplicity)

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        
        // Transfer tokens from user to contract
        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        Stake storage stake = stakes[msg.sender];
        
        // If user has an existing stake, add to it
        if (stake.amount > 0) {
            uint256 reward = calculateReward(msg.sender);
            stake.amount = stake.amount.add(_amount);
            emit Withdrawn(msg.sender, stake.amount, reward);
        } else {
            stake.startTime = block.timestamp;
            stake.amount = _amount;
            emit Staked(msg.sender, _amount);
        }
    }

    function withdraw() external {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount > 0, "No stake found");

        uint256 reward = calculateReward(msg.sender);
        uint256 totalAmount = stake.amount.add(reward);

        // Reset the stake
        stake.amount = 0;
        stake.startTime = 0;

        // Transfer the staked tokens and rewards back to the user
        require(stakingToken.transfer(msg.sender, totalAmount), "Transfer failed");

        emit Withdrawn(msg.sender, totalAmount, reward);
    }

    function calculateReward(address _user) public view returns (uint256) {
        Stake storage stake = stakes[_user];
        if (stake.amount == 0) return 0;
        uint256 stakingDuration = block.timestamp.sub(stake.startTime);
        return stakingDuration.mul(rewardRate).mul(stake.amount).div(1e18); // Reward rate is per second
    }

    function setRewardRate(uint256 _rate) external onlyOwner {
        rewardRate = _rate;
    }
}
