# YONA Smart Contract

This repository contains the YONA smart contract, an ERC20-compliant token with staking functionality. YONA is built on the Binance Smart Chain (BSC) and leverages OpenZeppelin's libraries for security and best practices.

## Features

- **ERC20 Token:** Implements the ERC20 standard.
- **Dual Ownership:** Managed by two distinct owners.
- **Minting Caps:**
  - Total Mint Cap: Equal to the initial supply.
  - Yearly Mint Cap: 10% of the total mint cap.
- **Staking System:**
  - Supports flexible and hard staking plans.
  - Dynamic reward scaling based on yearly mint cap utilization.
- **Security:**
  - Utilizes OpenZeppelin's `ReentrancyGuard` to prevent reentrancy attacks.
  - Enforces ownership constraints for administrative functions.

## Smart Contract Overview

### Constructor

The constructor initializes the token with:
- **Initial Supply:** Distributed equally between the two owners.
- **Ownership:** Owner1 is the contract deployer, and Owner2 is provided during deployment.

### Key Functionalities

#### Ownership
- **Transfer Ownership:** Allows transfer of ownership to two new addresses.

#### Staking Plans
- **Add Staking Plan:** Owners can add new staking plans with custom reward rates and durations.
- **Update Staking Plan:** Owners can modify plans with no active stakes.
- **Reward Scaling:** Dynamically adjusts reward rates if the yearly mint cap is nearing.

#### Staking and Unstaking
- **Stake Tokens:** Users can stake their tokens under a selected plan.
- **Unstake Tokens:** Users can unstake tokens and claim rewards based on staking duration and plan parameters.

## Deployment

The contract uses Solidity 0.8.0 and requires the OpenZeppelin library.

### Prerequisites
- Node.js
- Hardhat or Truffle
- OpenZeppelin Contracts

### Steps to Deploy
1. Clone this repository:
   ```bash
   git clone <repository-url>
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Compile the contract:
   ```bash
   npx hardhat compile
   ```
4. Deploy the contract:
   ```bash
   npx hardhat run scripts/deploy.js --network <network>
   ```

## Usage

### Minting
The total and yearly mint caps are enforced automatically. Rewards are minted when users unstake tokens, subject to the yearly mint cap.

### Staking
1. **Flexible Staking:**
   - Minimum duration: 1 day.
2. **Hard Staking:**
   - Fixed duration defined by the staking plan.

### Administrative Functions
- Only owners can add/update staking plans and transfer ownership.
- Reward rates can be scaled dynamically to maintain sustainability.

## Events
The contract emits the following events:
- `Staked`: When a user stakes tokens.
- `Unstaked`: When a user unstakes tokens and claims rewards.
- `PlanAdded`: When a new staking plan is added.
- `PlanUpdated`: When a staking plan is updated.
- `OwnershipTransferred`: When ownership is transferred to new owners.
- `RewardScaled`: When a staking plan's reward rate is adjusted.

## Security

### Measures Taken
- **Reentrancy Protection:** All critical functions use OpenZeppelin's `ReentrancyGuard`.
- **Ownership Validation:** Only designated owners can execute privileged functions.
- **Minting Caps:** Prevent over-minting to maintain tokenomics integrity.

### Audit
This contract has been audited to ensure adherence to best practices and security.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Contact
For inquiries, reach out to YONA TEAM at admin@yona.com.

