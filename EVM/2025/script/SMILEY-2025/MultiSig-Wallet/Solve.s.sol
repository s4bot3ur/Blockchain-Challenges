//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import {SetupLocker,Locker,signature} from "src/SMILEY-2025/MultiSig-Wallet/Locker.sol";
import "forge-std/StdJson.sol"; 

contract Solve is Script{
    using stdJson for string;
    
    function run()public{
        address _setup;
        string memory Setup_path=string.concat("broadcast/Deploy.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        try vm.readFile(Setup_path){
            string memory json = vm.readFile(Setup_path);
            address deployed = json.readAddress(".transactions[0].contractAddress");
            _setup=deployed;
        }catch{
            revert("Challenge Not Yet Deployed");
        }
        vm.startBroadcast();
        SetupLocker setup=SetupLocker(_setup);
        /*
        Implement your solution from here.
        */
        require(setup.isSolved(),"Chall Not Solved");
        vm.stopBroadcast();
    }
}

