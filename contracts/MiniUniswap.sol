// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/contracts@5.2.0/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts@5.2.0/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts@5.2.0/utils/math/Math.sol";

contract MiniUniswapV2 is ERC20 {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public constant FEE_NUMERATOR = 3;
    uint256 public constant FEE_DENOMINATOR = 1000;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpTokens);
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) ERC20("Mini Uniswap V2", "MUNI-LP"){ 
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external returns(uint256 lpTokens){
        require(amountA > 0 && amountB > 0, "Amount must be > 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if(totalSupply() == 0){
            lpTokens = Math.sqrt(amountA * amountB);
        } else {
            uint256 lpFromA = (amountA * totalSupply()) / reserveA;
            uint256 lpFromB = (amountB * totalSupply()) / reserveB;
            lpTokens = lpFromA < lpFromB ? lpFromA : lpFromB;
        }

        require(lpTokens > 0, "Insufficient liquidity minted");

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, lpTokens);
    }

    function removeLiquidity(uint256 lpTokens) external returns(uint256 amountA, uint256 amountB){
        require(lpTokens > 0, "Must burn > 0");
        require(balanceOf(msg.sender) >= lpTokens, "Insufficient lpTokens");

        amountA = (lpTokens * reserveA) / totalSupply();
        amountB = (lpTokens * reserveB) / totalSupply();
        require(amountA > 0 && amountB > 0, "Insufficient liquidity burned");

        _burn(msg.sender, lpTokens);

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpTokens);
    }

    function swap(address tokenIn, uint256 amountIn) external returns(uint256 amountOut){
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid Token");
        require(amountIn > 0, "Amount must be > 0");

        bool isTokenA = tokenIn == address(tokenA);
        (IERC20 inputToken, IERC20 outputToken, uint256 reserveIn, uint256 reserveOut) = isTokenA 
            ? (tokenA, tokenB, reserveA, reserveB)
            : (tokenB, tokenA, reserveB, reserveA);

        inputToken.transferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR);
        amountOut = (reserveOut * amountInWithFee) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);

        require(amountOut > 0, "Insufficient output");

        outputToken.transferFrom(msg.sender, amountOut);

        if(isTokenA){
            reserveA += amountA;
            reserveB += amountB;
        } else {
            reserveA -= amountA;
            reserveB -= amountB;
        }

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }
}