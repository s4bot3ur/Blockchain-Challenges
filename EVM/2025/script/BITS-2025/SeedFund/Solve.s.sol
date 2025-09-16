pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {AngelInvestor} from "src/BITS-2025/SeedFund/AngelInvestor.sol";
import "forge-std/StdJson.sol"; 


contract Solve is Script{
    using stdJson for string;
    
    function run()public{
        address _angel;
        string memory Setup_path=string.concat("broadcast/Deploy.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        try vm.readFile(Setup_path){
            string memory json = vm.readFile(Setup_path);
            address deployed = json.readAddress(".transactions[1].contractAddress");
            _angel=deployed;
        }catch{
            revert("Challenge Not Yet Deployed");
        }

        vm.startBroadcast();
        AngelInvestor angel=AngelInvestor(_angel);
        /*
        Implement your solution from here.
        */
        require(angel.isChallSolved(),"Challenge Not Solved");
        vm.stopBroadcast();
    }
}
