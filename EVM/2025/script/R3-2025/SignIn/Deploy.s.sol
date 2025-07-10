//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Setup} from "src/R3-2025/SignIn/Setup.sol";

contract Deploy is Script {
    address player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
    bytes32 player_PK=bytes32(0x0f98b3a5774fbfdf19646dba94a6c08f13f4c341502334a57724de46497192c3);
    function run() public {
        vm.startBroadcast();
        Setup _setup = new Setup();
        payable(player).transfer(1e18);
        vm.stopBroadcast();
    }
}
