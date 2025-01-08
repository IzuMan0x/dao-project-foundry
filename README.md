# DAO project

- trello board https://trello.com/b/bOGxJpTY/dao-project

- discord https://discord.gg/DVDtsbHp

# Summary

- You can read deploy steps [here](#deploy-steps)

## DAO

DAO controls all the contracts via proposals that are queued and executed by the Timelock

- can do:

  - sets fee

  - add/remove supported tokens

  - remove companies that don't follow guidelines

  - change threshold, quorumVotes and so on

## Staking

Contract to handle staking.

Staking can be with a fixed or variable duration.

## Token Sale

There's different token sales.

- #0 is just for founder (or any other initial supporter) and it's just so that DAO can start functioning (threshold 0.5%)

- #1 is the official token sale with same price of #0

Both #0 and #1 (and we should add like a flag so we can set each one if they follow this rule) all tokens are added as liquidity to uniswap and token_LP is staked for a fixed staking period.

Both #0 and #1 (same of above we might need to add a flag) voting power is delegated to founder (or multisig or something like that) so that we wait for token distribution before DAO has full power.

## WerewolfToken

This is the contract for the token.

## CompaniesHouse

It's were an user can create and manage a company.

the owner can hire/fire/pay employees/collaborators.

This will be connected to an off chain accounting/ERP software. I think it could be some sort of oracle. I'd like to be able to audit a company with one click and see all financial/economy data with 100% accuracy.

## Treasury

This is the treasury for the DAO but I was thinking that each company should have a treasury? or the treasury will be the wallet of the company itself?

# Roles

## Admin

What does admin do that it cannot be done by DAO?

## User

Can:

- stake tokens

- claim rewards

- CRUD company

- if token holder can create/vote proposals

## Company employee

roles:

- founder

- CEO

- HHR: head human resources

- dev

- ...

# Style Guidelines

...

# Deploy Steps:

1. **Deploy Contracts**  
   The founder deploys the following contracts in sequence:

   - `WerewolfTokenV1` with references to `Treasury` and `Timelock`.
   - `Treasury` and `Timelock` for managing funds and governance, respectively.
   - `Staking` for managing long-term token locking.
   - `DAO` for governance proposals and voting.
   - `TokenSale` for managing token sales.
   - `UniswapHelper` for facilitating Uniswap liquidity operations.

2. **USDT Configuration**

   - If testing locally or on a non-mainnet network, deploy `MockUSDT` and assign its address.
   - If on the mainnet or a specific testnet, use the appropriate USDT address.

3. **Airdrop WLF Tokens**

   - Airdrop 5,000,000 `WLF` tokens to the `TokenSale` contract.

4. **Start Token Sale #0**

   - Begin the initial token sale by invoking `startSaleZero` with 5,000,000 WLF tokens at a price of 0.001 USDT per token.

5. **Ownership Transfer**

   - Transfer ownership of `WerewolfTokenV1`, `Treasury`, and `TokenSale` to the `Timelock` contract to ensure decentralized governance.

6. **Buy Tokens**

   - The founder buys 5,000,000 `WLF` tokens for 5,000 USDT by invoking the `buyTokens` function.
   - This process involves approvals for `TokenSale` to spend WLF and USDT on behalf of the founder.

7. **Add Liquidity to Uniswap**

   - Add the WLF/USDT pair to Uniswap using the `UniswapHelper` contract. The liquidity includes:
     - 5,000,000 WLF tokens.
     - 5,000 USDT.

8. **Stake Liquidity Pool Tokens**

   - Stake the `WLF_USDT_LP` tokens into the `Staking` contract for a duration of 5 years.

9. **Proposal and Voting**
   - The founder proposes and votes for `tokenSale#1` using the `DAO` contract. This ensures the governance system is functional and the next token sale is prepared.


