// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Setup,Chal} from "src/Setup.sol";

contract Deploy is Script{


    function run()public{
        vm.startBroadcast();
        Setup setup=new Setup();
        vm.stopBroadcast();
    }
}
