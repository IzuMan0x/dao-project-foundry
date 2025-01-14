// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./WerewolfTokenV1.sol";
import "./Treasury.sol";
import "./Staking.sol";

// Define an interface for UniswapHelper to interact with it
interface ILiquidityExamples {
    function addLiquidity(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 tokenId);
}

interface IUniswapHelper {
    function addLiquidity(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (uint256 tokenId);
}

contract TokenSale is OwnableUpgradeable {
    WerewolfTokenV1 private werewolfToken;
    Treasury private treasury;
    address public usdtTokenAddress;
    IERC20 public usdtToken;
    Staking public stakingContract;
    ILiquidityExamples public liquidityExamplesContract;

    // BUG: test
    IUniswapHelper public uniswapHelper;
    //
    uint256 public price;
    uint256 public saleIdCounter = 0;
    bool public saleActive;

    struct Sale {
        uint256 saleId;
        uint256 tokensAvailable;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Sale) public sales;

    event SaleStarted(uint256 saleId, uint256 tokensAvailable, uint256 price);
    event SaleEnded(uint256 saleId);
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 saleId);

    // BUG: remove address _uniswapHelper
    constructor() 
    /* address _token,
        address _treasury,
        address _timelock,
        address _usdtTokenAddress,
        address _stakingAddress,
        address _uniswapHelper */
    {
        /*      require(_usdtTokenAddress != address(0), "USDT address cannot be zero");
        usdtTokenAddress = _usdtTokenAddress;
        usdtToken = IERC20(_usdtTokenAddress);
        werewolfToken = WerewolfTokenV1(_token);
        stakingContract = Staking(_stakingAddress);
        treasury = Treasury(_treasury);
        uniswapHelper = IUniswapHelper(_uniswapHelper);
        // Set floor price for token sales
        price = 0.001 * 10 ** 18; */

        //disable initializer
        _disableInitializers();
    }

    function initialize(
        address newOwner,
        address _token,
        address _treasury,
        address _timelock,
        address _usdtTokenAddress,
        address _stakingAddress,
        address _uniswapHelper
    ) public initializer {
        __Ownable_init(newOwner); //we do not want the msg.sender to be the owner since that will be the proxyAdmin
        require(_usdtTokenAddress != address(0), "USDT address cannot be zero");
        usdtTokenAddress = _usdtTokenAddress;
        usdtToken = IERC20(_usdtTokenAddress);
        werewolfToken = WerewolfTokenV1(_token);
        stakingContract = Staking(_stakingAddress);
        treasury = Treasury(_treasury);
        uniswapHelper = IUniswapHelper(_uniswapHelper);
        // Set floor price for token sales
        price = 0.001 * 10 ** 18;
    }

    function setUsdtTokenAddress(address _usdtTokenAddress) external onlyOwner {
        require(_usdtTokenAddress != address(0), "USDT address cannot be zero");
        usdtTokenAddress = _usdtTokenAddress;
        usdtToken = IERC20(_usdtTokenAddress);
    }

    function startSaleZero(uint256 _amount, uint256 _price) external onlyOwner {
        require(!saleActive, "Sale is already active.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(_price >= price, "Price must be greater or equal to prev price.");
        require(werewolfToken.balanceOf(address(this)) >= _amount, "Not enough tokens for sale.");

        sales[saleIdCounter] = Sale(saleIdCounter, _amount, _price, true);
        price = _price;
        saleActive = true;

        emit SaleStarted(saleIdCounter, _amount, _price);
    }

    function startSale(uint256 _amount, uint256 _price) external onlyOwner {
        require(!saleActive, "Sale is already active.");
        require(_amount > 0, "Amount must be greater than zero.");
        require(_price >= price, "Price must be greater or equal to prev price.");
        require(werewolfToken.balanceOf(address(this)) >= _amount, "Not enough tokens for sale.");

        saleIdCounter++;
        sales[saleIdCounter] = Sale(saleIdCounter, _amount, _price, true);
        price = _price;
        saleActive = true;

        emit SaleStarted(saleIdCounter, _amount, _price);
    }

    function buyTokens(
        uint256 _amount,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external {
        require(saleActive, "Sale is not active");
        Sale storage currentSale = sales[saleIdCounter];
        require(currentSale.tokensAvailable >= _amount, "Not enough tokens available for sale");

        uint256 tokenAmount = amount0Desired; //_amount * 10 ** werewolfToken.decimals();
        uint256 usdtRequired = amount1Desired; //_amount * currentSale.price;

        // Transfer USDT from buyer to staking contract
        require(usdtToken.transferFrom(msg.sender, address(stakingContract), usdtRequired), "USDT transfer failed");

        // Transfer tokens to staking contract
        currentSale.tokensAvailable -= _amount;
        require(
            werewolfToken.transfer(address(stakingContract), tokenAmount), "Token transfer to staking contract failed"
        );

        // // Stake tokens in staking contract for msg.sender with a 10-year lock
        // stakingContract.stakeFixedDuration(
        //     msg.sender,
        //     tokenAmount,
        //     5 * 365 days
        // );

        // // Call the addLiquidity function on the helper contract
        // uint256 tokenId = uniswapHelper.addLiquidity(
        //     token0,
        //     token1,
        //     fee,
        //     tickLower,
        //     tickUpper,
        //     amount0Desired,
        //     amount1Desired
        // );

        emit TokensPurchased(msg.sender, _amount, saleIdCounter);

        // End the sale if no tokens are left
        if (currentSale.tokensAvailable == 0) {
            _endSale();
        }
    }

    function _endSale() internal {
        require(saleActive, "Sale is not active");
        sales[saleIdCounter].active = false;
        saleActive = false;

        emit SaleEnded(saleIdCounter);
    }

    function endSale() external onlyOwner {
        _endSale();
    }
}
