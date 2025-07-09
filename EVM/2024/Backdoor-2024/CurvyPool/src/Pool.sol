// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./LiquidityToken.sol";

error Pool__InvalidTokenRatio();
error Pool__ZeroLiquidityToken();
error Pool__InvalidToken();


contract Pool is LiquidityToken {

    IERC20 private immutable i_token0;
    IERC20 private immutable i_token1;

    uint256 private s_reserve0;
    uint256 private s_reserve1;


    uint8 private immutable i_fee;

    event AddedLiquidity(
        uint256 indexed liquidityToken,
        address token0,
        uint256 indexed amount0,
        address token1,
        uint256 indexed amount1
    );

    event RemovedLiquidity(
        uint256 indexed liquidityToken,
        address token0,
        uint256 indexed amount0,
        address token1,
        uint256 indexed amount1
    );

    event Swapped(
        address tokenIn,
        uint256 indexed amountIn,
        address tokenOut,
        uint256 indexed amountOut
    );

    constructor(
        address token0,
        address token1,
        uint8 fee
    ) LiquidityToken("Backdoor Token", "BT") {
        i_token0 = IERC20(token0);
        i_token1 = IERC20(token1);
        i_fee = fee;
        s_reserve0 = 0;
        s_reserve1 = 0;
        i_token0.approve(address(this), type(uint256).max);
        i_token1.approve(address(this), type(uint256).max);
    }

    

    function _updateLiquidity(uint256 reserve0, uint256 reserve1) internal {
        s_reserve0 = reserve0;
        s_reserve1 = reserve1;
    }

    function swap(address _tokenIn, uint256 amountIn) external {
        // Objective: To Find amount of Token Out
        (uint256 amountOut, uint256 resIn, uint256 resOut, bool isToken0) = getAmountOut(_tokenIn, amountIn);

        IERC20 token0 = i_token0; // gas optimization
        IERC20 token1 = i_token1; // gas optimization

        (uint256 res0, uint256 res1, IERC20 tokenIn, IERC20 tokenOut) = isToken0
            ? (resIn + amountIn, resOut - amountOut, token0, token1)
            : (resOut - amountOut, resIn + amountIn, token1, token0);
        bool success = tokenIn.transferFrom(msg.sender, address(this), amountIn);
        require(success, "Swap Failed");

        _updateLiquidity(res0, res1);
        tokenOut.transfer(msg.sender, amountOut);

        emit Swapped(address(tokenIn), amountIn, address(tokenOut), amountOut);
    }



    function addLiquidity(uint256 amount0, uint256 amount1) external {
        uint256 reserve0 = s_reserve0; // gas optimization
        uint256 reserve1 = s_reserve1; // gas optimization
        if (amount0 < 0 || amount1 < 0) {
            revert Pool__InvalidTokenRatio();
        }

        IERC20 token0 = i_token0; // gas optimization
        IERC20 token1 = i_token1; // gas optimization

        token0.transferFrom(msg.sender, address(this), amount0);
        token1.transferFrom(msg.sender, address(this), amount1);

        uint256 liquidityTokens = ((amount0*amount0) + (amount1*amount1))/(1 ether);
        //2e18*2e18
        //4e18
        if (liquidityTokens == 0) revert Pool__ZeroLiquidityToken();
        _mint(msg.sender, liquidityTokens);
        _updateLiquidity(reserve0 + amount0, reserve1 + amount1);

        emit AddedLiquidity(
            liquidityTokens,
            address(token0),
            amount0,
            address(token1),
            amount1
        );
    }

    function removeLiquidity(uint256 liquidityTokens) external {
        (uint256 amount0, uint256 amount1) = getAmountsOnRemovingLiquidity(liquidityTokens);

        _burn(msg.sender, liquidityTokens);
        _updateLiquidity(s_reserve0 - amount0, s_reserve1 - amount1);

        IERC20 token0 = i_token0; // gas optimization
        IERC20 token1 = i_token1; // gas optimization

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        emit RemovedLiquidity(
            liquidityTokens,
            address(token0),
            amount0,
            address(token1),
            amount1
        );
    }

    function getAmountsOnRemovingLiquidity(uint256 liquidityTokens) public view returns(uint256 amount0, uint256 amount1){
        require(liquidityTokens > 0, "0 Liquidity Tokens");
        amount0 = liquidityTokens/2;
        amount1 = liquidityTokens/2;
    }

    function getAmountOut(
        address _tokenIn,
        uint amountIn
    ) public view returns (uint, uint , uint , bool) {
        require(
            _tokenIn == address(i_token0) || _tokenIn == address(i_token1),
            "Invalid Token"
        );

        bool isToken0 = _tokenIn == address(i_token0) ? true : false;

        uint256 reserve0 = s_reserve0; // gas optimization
        uint256 reserve1 = s_reserve1; // gas optimization

        (
            uint256 resIn,
            uint256 resOut
        ) = isToken0
                ? (reserve0, reserve1)
                : (reserve1, reserve0);

        uint256 amountInWithFee = (amountIn * (10000 - i_fee)) / 10000;
        uint256 amountOut = amountInWithFee;
        return (amountOut, resIn, resOut, isToken0);
    }

    function getReserves() public view returns (uint256, uint256) {
        return (s_reserve0, s_reserve1);
    }

    function getTokens() public view returns (address, address) {
        return (address(i_token0), address(i_token1));
    }

    function getFee() external view returns (uint8) {
        return i_fee;
    }

}