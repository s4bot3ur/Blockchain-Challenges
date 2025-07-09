// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "lib/forge-std/src/Script.sol";

interface IEasyChallenge{
    function unlock(uint slot) external;
    function isKey()external view returns(uint256);
}

interface ISetup{
    function challengeInstane() external view returns(IEasyChallenge);
    
}
contract Solve is Script{
    ISetup setup;
    uint constant isKey = 0x1337;
    uint baseSlot = 1;
    function run()public{
        address _setup=address(0x829AE10DdB4AC5FEFc4dFcA593b6589E85939207);
        vm.startBroadcast();
        setup=ISetup(_setup);
        IEasyChallenge challenge=setup.challengeInstane();
        uint256 slot=uint256(keccak256(abi.encodePacked(isKey, baseSlot)));
        challenge.unlock(slot);
        vm.stopBroadcast();
    }
}