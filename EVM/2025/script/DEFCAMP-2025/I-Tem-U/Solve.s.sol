pragma solidity ^0.8.0;

import {Script,console} from "forge-std/Script.sol";
import {TemU} from "src/DEFCAMP-2025/I-Tem-U/TemU.sol";
import {iTems} from "src/DEFCAMP-2025/I-Tem-U/iTems.sol";
import {Tem} from "src/DEFCAMP-2025/I-Tem-U/Tem.sol";
import {ERC1155Holder} from "lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "forge-std/StdJson.sol"; 

contract Solve is Script{
    using stdJson for *;
    function run()public{
        address temu;
        string memory Setup_path=string.concat("broadcast/Deploy.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        try vm.readFile(Setup_path){
            string memory json = vm.readFile(Setup_path);
            address deployed = json.readAddress(".transactions[1].contractAddress");
            temu=deployed;
        }catch{
            revert("Challenge Not Yet Deployed");
        }
        vm.startBroadcast();
        TemU market=TemU(address(temu));
        /*
        Implement your solution from here.
        */
        vm.stopBroadcast();
    }
}
