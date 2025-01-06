# DAO project

- trello board https://trello.com/b/bOGxJpTY/dao-project

- discord https://discord.gg/DVDtsbHp

## Deploy Steps:

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

#### Notes:

- Ensure all operations involving token transfers, staking, and approvals are logged and verified using assertions similar to the provided test cases.
- Simulate necessary delays or mine blocks using helper functions to ensure accurate testing of time-sensitive features.

# Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
