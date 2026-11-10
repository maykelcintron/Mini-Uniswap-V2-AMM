# 🦄 MiniUniswapV2 — Automated Market Maker (AMM)

> **Architectural & Security Overview:** `MiniUniswapV2` is a simplified, educational implementation of a constant-product Automated Market Maker (AMM) inspired by Uniswap V2. It enables permissionless token swaps and liquidity provision using standard ERC20 tokens.

---

## 🏗️ 1. System Architecture & Features

The contract acts as a unified liquidity pool and LP token smart contract. It combines an ERC20 token implementation (`MUNI-LP`) with decentralized exchange logic for two underlying tokens (`tokenA` and `tokenB`).

### Core Features:
- **Constant-Product Market Making:** Implements the $x \cdot y = k$ invariant for automated price discovery.
- **Liquidity Provider (LP) Tokens:** Mints `MUNI-LP` tokens to represent proportional ownership of the liquidity pool.
- **Swap Mechanism with Protocol Fee:** Implements token swaps with an integrated **0.3% fee** (`3 / 1000`), accruing directly into the pool reserves to reward liquidity providers.
- **OpenZeppelin v5.2.0 Integration:** Uses standard math utilities and secure ERC20 interfaces.

---

## 📊 2. Mathematical Model & Formulae

| Parameter / Metric | Mathematical Formula | Description |
| :--- | :---: | :--- |
| **Protocol Swap Fee** | $0.3\%$ (`3 / 1000`) | Deducted from the input amount before executing the constant-product swap. |
| **Initial LP Supply** | $L_0 = \sqrt{\Delta a \cdot \Delta b}$ | Minted using the geometric mean when the pool is first initialized. |
| **Subsequent LP Supply** | $L = \min\left(\frac{\Delta a \cdot L_{\text{total}}}{R_A}, \frac{\Delta b \cdot L_{\text{total}}}{R_B}\right)$ | Minted proportionally based on the minimum share added to avoid pool imbalance. |
| **Swap Output Formula** | $\Delta y = \frac{R_y \cdot \Delta x_{\text{fee}}}{R_x + \Delta x_{\text{fee}}}$ | Derived from $(R_x + \Delta x_{\text{fee}})(R_y - \Delta y) = R_x R_y$. |

---

## 🔒 3. Security Analysis & Bug Report

> ⚠️ **Auditor Notice:** The initial implementation contains two key bugs in the `swap()` function that must be addressed before deployment:

1. **Incorrect Transfer Direction in Swap:** 
   The original function calls `outputToken.transferFrom(msg.sender, amountOut)`, attempting to pull output tokens from the caller. It must be updated to `outputToken.transfer(msg.sender, amountOut)` to send tokens from the pool contract to the user.
2. **Incorrect Reserve Accounting:** 
   The reserve state updates in `swap()` use undefined variables (`amountA`, `amountB`) instead of correctly incrementing the input reserve by `amountIn` and decrementing the output reserve by `amountOut`.

---

## 🛠️ 4. Public Function Interface

- `addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 lpTokens)`  
  Deposits `tokenA` and `tokenB` into the contract and mints proportional `MUNI-LP` tokens to `msg.sender`.
- `removeLiquidity(uint256 lpTokens) external returns (uint256 amountA, uint256 amountB)`  
  Burns `MUNI-LP` tokens and returns the underlying `tokenA` and `tokenB` share to `msg.sender`.
- `swap(address tokenIn, uint256 amountIn) external returns (uint256 amountOut)`  
  Swaps `amountIn` of `tokenIn` for the calculated amount of the opposite token, taking the 0.3% protocol fee into account.
