//SPDX-License-Identifier-MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Setup,CasinoPWNME} from "src/PWNME-2025/Mafia-At-The-End-Of-Block-2/Setup.sol";


contract Deploy is Script{
    function run()public{
        address player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
        bytes32 player_PK=bytes32(0x0f98b3a5774fbfdf19646dba94a6c08f13f4c341502334a57724de46497192c3);
        vm.startBroadcast();
        Setup setup=new Setup();
        payable(player).transfer(1e18);
        vm.stopBroadcast();
    }
}