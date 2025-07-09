// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {KittyKittyBank} from "../src/KittyKittyBank.sol";
import {Script,console} from "forge-std/Script.sol";
import {Setup} from "../src/Setup.sol";

contract Deploy is Script{
    function run()public{
        vm.startBroadcast();
        Setup setup=new Setup{value:100 ether}();
        vm.stopBroadcast();
    }
}