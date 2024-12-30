// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {WerewolfTokenV1} from "../src/WerewolfTokenV1.sol";
import {Treasury} from "../src/Treasury.sol";
import {TokenSale} from "../src/TokenSale.sol";
import {Timelock} from "../src/Timelock.sol";
import {DAO} from "../src/DAO.sol";
import {Staking} from "../src/Staking.sol";
import {UniswapHelper} from "../src/UniswapHelper.sol";
import {MockUSDT} from "../src/MockUSDT.sol";

contract DeployTest is Test {
    // Contract instances
    WerewolfTokenV1 werewolfToken;
    Treasury treasury;
    TokenSale tokenSale;
    Timelock timelock;
    DAO dao;
    Staking staking;
    UniswapHelper uniswapHelper;
    MockUSDT mockUSDT;

    // Addresses
    address founder;
    address addr1;
    address addr2;

    // Constants
    uint256 constant votingPeriod = 2 days;
    uint256 constant tokenSaleAirdrop = 5_000_000 ether;
    uint256 constant tokenPrice = 0.001 ether;

    function setUp() public {
        // Set up signers
        founder = address(this);
        addr1 = address(0x1);
        addr2 = address(0x2);

        // Deploy MockUSDT
        mockUSDT = new MockUSDT(1_000_000 ether);

        // Deploy UniswapHelper
        uniswapHelper = new UniswapHelper(founder);

        // Deploy Treasury
        treasury = new Treasury(founder);

        // Deploy Timelock
        timelock = new Timelock(founder, votingPeriod);

        // Deploy WerewolfTokenV1
        werewolfToken = new WerewolfTokenV1(
            address(treasury),
            address(timelock),
            founder,
            addr1
        );

        // Deploy Staking
        staking = new Staking(address(werewolfToken), address(timelock));

        // Deploy DAO
        dao = new DAO(
            address(werewolfToken),
            address(treasury),
            address(timelock)
        );

        // Deploy TokenSale
        tokenSale = new TokenSale(
            address(werewolfToken),
            address(treasury),
            address(timelock),
            address(mockUSDT),
            address(staking),
            address(uniswapHelper)
        );

        // Airdrop tokens to TokenSale contract
        werewolfToken.airdrop(address(tokenSale), tokenSaleAirdrop);

        // Start Token Sale #0
        tokenSale.startSaleZero(tokenSaleAirdrop, tokenPrice);

        // Transfer ownerships
        werewolfToken.transferOwnership(address(timelock));
        treasury.transferOwnership(address(timelock));
        tokenSale.transferOwnership(address(timelock));
    }

    function test_AirdropToTokenSale() public {
        uint256 tokenSaleBalance = werewolfToken.balanceOf(address(tokenSale));
        assertEq(tokenSaleBalance, tokenSaleAirdrop);
    }

    function test_StartTokenSaleZero() public {
        uint256 saleCounter = tokenSale.saleIdCounter();
        (
            uint256 saleId,
            uint256 tokensAvailable,
            uint256 price,
            bool active
        ) = tokenSale.sales(saleCounter);
        bool saleActive = tokenSale.saleActive();

        assertEq(tokensAvailable, tokenSaleAirdrop);
        assertEq(price, tokenPrice);
        assertTrue(saleActive);
    }

    function test_TransferOwnershipToTimelock() public {
        assertEq(werewolfToken.owner(), address(timelock));
        assertEq(treasury.owner(), address(timelock));
        assertEq(tokenSale.owner(), address(timelock));
    }

    function test_FounderBuyTokens() public {
        uint256 founderWLFBalanceBefore = werewolfToken.balanceOf(founder);
        uint256 founderUSDTBalanceBefore = mockUSDT.balanceOf(founder);

        // Approve TokenSale contract to spend tokens
        werewolfToken.approve(address(tokenSale), tokenSaleAirdrop);
        mockUSDT.approve(address(tokenSale), 5000 ether);

        // Buy tokens
        tokenSale.buyTokens(
            tokenSaleAirdrop,
            address(werewolfToken),
            address(mockUSDT),
            100,
            -887272,
            887272,
            tokenSaleAirdrop,
            5000 ether
        );

        uint256 founderWLFBalanceAfter = werewolfToken.balanceOf(founder);
        uint256 founderUSDTBalanceAfter = mockUSDT.balanceOf(founder);
        uint256 stakingWLFBalance = werewolfToken.balanceOf(address(staking));
        uint256 stakingUSDTBalance = mockUSDT.balanceOf(address(staking));

        assertEq(stakingWLFBalance, tokenSaleAirdrop);
        assertEq(
            founderUSDTBalanceAfter,
            founderUSDTBalanceBefore - 5000 ether
        );
        assertEq(stakingUSDTBalance, 5000 ether);
    }
}
