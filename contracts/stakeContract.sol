// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract EtherStaking {
    struct Stake {
        uint256 amount;          // Amount of Ether staked by the user
        uint256 startTime;       // Timestamp when the stake was made
        bool withdrawn;          // Track if the stake has been withdrawn
    }

    // Mapping to store staking details of each user
    mapping(address => Stake) public stakes;
    // Total staked Ether in the contract
    uint256 public totalStaked;
    // Reward rate per second (this rate is just an example)
    uint256 public rewardRate = 1 ether / 1000000; // Example rate (modify as needed)

    // Event emitted when a user stakes Ether
    event Staked(address indexed user, uint256 amount);
    // Event emitted when a user withdraws their stake and rewards
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    // Modifier to check if the caller has an active stake
    modifier hasStaked(address _staker) {
        require(stakes[_staker].amount > 0, "No active stake found");
        _;
    }

    // Function to allow users to stake Ether
    function stake() external payable {
        require(msg.value > 0, "Stake amount must be greater than zero");

        // Update the user's stake details
        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].startTime = block.timestamp;
        stakes[msg.sender].withdrawn = false;

        // Update the total staked Ether in the contract
        totalStaked += msg.value;

        emit Staked(msg.sender, msg.value);
    }

    // Function to calculate rewards based on staking duration
    function calculateReward(address _staker) public view hasStaked(_staker) returns (uint256) {
        Stake memory stakeData = stakes[_staker];
        uint256 stakingDuration = block.timestamp - stakeData.startTime;
        uint256 reward = stakingDuration * rewardRate * stakeData.amount / 1 ether; // Reward proportional to time and staked amount
        return reward;
    }

    // Function to withdraw staked Ether and earned rewards
    function withdraw() external hasStaked(msg.sender) {
        Stake storage stakeData = stakes[msg.sender];
        require(!stakeData.withdrawn, "Stake already withdrawn");

        // Calculate the reward for the staker
        uint256 reward = calculateReward(msg.sender);

        // Withdraw the staked amount and reward
        uint256 totalWithdrawal = stakeData.amount + reward;

        // Update contract state before transfer to prevent reentrancy attacks
        stakeData.amount = 0;
        stakeData.withdrawn = true;
        totalStaked -= stakeData.amount;

        // Transfer the staked Ether and reward to the staker
        (bool success, ) = msg.sender.call{value: totalWithdrawal}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, stakeData.amount, reward);
    }

    // Fallback function to handle accidental Ether transfers
    receive() external payable {
        revert("Use stake function to send Ether");
    }
}
