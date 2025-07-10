//SPDX-License-Identifier:MIT

import {Script} from "forge-std/Script.sol";
import {Locker,SetupLocker} from "src/SMILEY-2025/MultiSig-Wallet/Locker.sol";

contract Deploy is Script{

    function run()public{
        address player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
        bytes32 player_PK=bytes32(0x0f98b3a5774fbfdf19646dba94a6c08f13f4c341502334a57724de46497192c3);
        vm.startBroadcast();
        SetupLocker setup=new SetupLocker(player);
        setup.deploy();
        payable(player).transfer(1e18);
        vm.stopBroadcast();
    }
}