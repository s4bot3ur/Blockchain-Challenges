//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {TrillionEther} from "../src/TrillionEther.sol";

contract Deploy is Script{

    function run()public{
        vm.startBroadcast();
        new TrillionEther{value: 1_000_000_000_000 ether}();
        vm.stopBroadcast();
    }
}