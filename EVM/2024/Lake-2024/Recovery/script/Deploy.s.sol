// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "@forge-std-1.9.1/src/Script.sol";

import {Recovery} from "src/Recovery.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();

        Recovery challenge = new Recovery();

        vm.writeFile(vm.envOr("OUTPUT_FILE", string("/tmp/deploy.txt")), vm.toString(address(challenge)));
    }
}
