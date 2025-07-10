pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {Setup} from "src/HTB-CyberApocalypse-2025/Helios-Dex/Setup.sol";

contract Deploy is Script{
    function run()public{
        address player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
        bytes32 player_PK=bytes32(0x0f98b3a5774fbfdf19646dba94a6c08f13f4c341502334a57724de46497192c3);
        vm.startBroadcast();
        Setup setup=new Setup{value:1000 ether}(player);
        payable(player).send(1e18);
        vm.stopBroadcast();
    }
}
