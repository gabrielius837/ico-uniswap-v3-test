//SPDX-License-Identifier: Unlicense
pragma solidity >= 0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

import "./Token.sol";

contract Ico is Ownable {
    uint256 private balance;
    //address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWETH9 private constant WETH = IWETH9(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    INonfungiblePositionManager private constant POSITION_MANAGER = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    uint24 private constant POOL_FEE = 3000;
    // square root of 1:1000 ratio stored as Q96.64 number
    // solhint-disable-next-line const-name-snakecase
    uint160 private constant sqrtPriceX96 = 2505414483750479311864138015;
    int24 private constant MIN_TICK = -887272;
    Token private token;
    bool private liquidityResolved;

    constructor() {
        token = new Token("test", "CASE");
        POSITION_MANAGER.createAndInitializePoolIfNecessary(
            address(token),
            address(WETH),
            POOL_FEE,
            sqrtPriceX96
        );
    }

    function getBalance() external view returns(uint256) {
        return balance;
    }

    function tokenAddress() external view returns(address) {
        return address(token);
    }

    function donate() external payable onlyNonZero onlyUnresolved {
        balance += msg.value;
        uint256 amount = msg.value * 1000;
        token.mint(msg.sender, amount);
    }

    function resolveLiquidity() external payable onlyOwner onlyUnresolved {
        liquidityResolved = true;
        uint256 tokenBalance = token.totalSupply();
        token.mint(address(this), tokenBalance);
        token.approve(address(this), tokenBalance);
        WETH.deposit{ value: balance }();
        balance = 0;
        WETH.approve(address(this), balance);
        TokenParams memory wethParams = TokenParams(address(WETH), balance, balance * 99 / 100);
        TokenParams memory tokenParams = TokenParams(address(token), tokenBalance, tokenBalance * 99 / 100);
        (TokenParams memory token0, TokenParams memory token1) = wethParams.adr < tokenParams.adr ? (wethParams, tokenParams) : (tokenParams, wethParams);
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams(
            token0.adr,
            token1.adr,
            POOL_FEE,
            MIN_TICK,
            -MIN_TICK,
            token0.balance,
            token1.balance,
            token0.minBalance,
            token1.minBalance,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp + 30
        );
        POSITION_MANAGER.mint(mintParams);
    }

    struct TokenParams {
        address adr;
        uint256 balance;
        uint256 minBalance;
    }

    modifier onlyNonZero() {
        require(msg.value > 0, "ZERO");
        _;
    }

    modifier onlyUnresolved() {
        require(!liquidityResolved, "RESOLVED");
        _;
    }
}