pragma solidity ^0.8.0;

import {Script,console} from "forge-std/Script.sol";


import {Challenge,Vault,VaultFactory,Token} from "src/CREW_2025/breithorn/Challenge.sol";

contract Deploy is Script{

    function run()public{
        vm.startBroadcast();
        address player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
        Challenge chall=new Challenge();
        payable(player).call{value:1 ether}("");
        vm.stopBroadcast();
    }
}