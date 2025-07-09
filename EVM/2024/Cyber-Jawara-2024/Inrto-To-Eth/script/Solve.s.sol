// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Setup} from "src/Setup.sol";
import {Script,console} from "forge-std/Script.sol";


contract Solve is Script{

    function run()public{
        Setup setup = Setup(/**YOUR SETUP ADDRESS */);
        bytes memory _password = (bytes("CJ_INTERNATIONAL_2024-CHOVID99"));
        vm.startBroadcast();
        setup.solve(abi.encodePacked(_password));
        require(setup.isSolved(), "Exploit Failed");
        vm.stopBroadcast();
    }
}
