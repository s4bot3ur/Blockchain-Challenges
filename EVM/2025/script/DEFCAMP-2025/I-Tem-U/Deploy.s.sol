pragma solidity ^0.8.0;


import {Script,console} from "forge-std/Script.sol";
import {TemU} from "src/DEFCAMP-2025/I-Tem-U/TemU.sol";
import {iTems} from "src/DEFCAMP-2025/I-Tem-U/iTems.sol";
import {Tem} from "src/DEFCAMP-2025/I-Tem-U/Tem.sol";

contract Deploy is Script{

    function run()public{
        address player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
        vm.startBroadcast();
        iTems token=new iTems(address(0),100);
        TemU temu=new TemU(address(token));
        Tem tem =new Tem(address(token),address(temu));
        payable(address(player)).call{value:1e18}("");
        token.temHappi(address(tem));
        token.freeGold(address(temu), 1000000000000000000);
        tem.sellTem();
        vm.stopBroadcast();
        console.log("TOKEN :",address(token));
        console.log("TEMU :",address(temu));
        console.log("TEM :",address(tem));

        
    }
}