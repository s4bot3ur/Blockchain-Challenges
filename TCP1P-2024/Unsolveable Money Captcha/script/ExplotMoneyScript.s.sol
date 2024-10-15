// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {ExploitMoney} from "./ExploitMoney.sol";

contract ExploitMoneyScript is Script {
    function run() public {
        vm.startBroadcast();
        ExploitMoney exploitmoney = new ExploitMoney{value: 10 ether}();
        exploitmoney.Exploit();
        vm.stopBroadcast();
    }
}
