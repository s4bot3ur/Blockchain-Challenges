pragma solidity ^0.8.0;

import {Script,console} from "forge-std/Script.sol";

import {Challenge,Vault,VaultFactory,Token} from "src/CREW_2025/breithorn/Challenge.sol";
import {Account} from "src/CREW_2025/breithorn/lib/Account.sol";
import "forge-std/StdJson.sol"; 

contract Solve is Script{
    using stdJson for *;
    function run()public{
        string memory deploy_path=string.concat("broadcast/Deploy.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        Challenge chall;
        try vm.readFile(deploy_path){
            string memory json = vm.readFile(deploy_path);
            address deployed = json.readAddress(".transactions[0].contractAddress");
            chall=Challenge(deployed);
        }catch{
            revert("Challenge Not Yet Deployed");
        }
        string memory exploit_path=string.concat("broadcast/Solve.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        try vm.readFile(exploit_path){
            string memory json = vm.readFile(exploit_path);
            address deployed = json.readAddress(".transactions[0].contractAddress");
            vm.startBroadcast();
            Exploit exploit=Exploit(deployed);
            //PART-2

            require(chall.isSolved(),"Challenge Not Solved");
            vm.stopBroadcast();
            
        }catch{
            console.log("CATCH");
            vm.startBroadcast();
            //PART-1
            vm.stopBroadcast();
        }

    }   

}


contract Exploit{

}