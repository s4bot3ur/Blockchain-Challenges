pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {Setup,HeliosDEX} from "src/HTB-CyberApocalypse-2025/Helios-Dex/Setup.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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
        Setup setup=Setup(_setup);
        address player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
        /*
        Implement your solution from here.
        */
        require(setup.isSolved(),"Chall Not Solved");
        vm.stopBroadcast();
    }
}

