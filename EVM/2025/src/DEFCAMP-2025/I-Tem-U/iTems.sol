// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import  {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import  "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";


library Items {
    uint256 internal constant GOLD = 0;
    uint256 internal constant DAGEROUS_DAGER = 1;
    uint256 internal constant TEM_FAV_ITEM = 2;
}

contract iTems is ERC1155, Ownable {

 
    constructor(address tem,uint amount) ERC1155("") Ownable(msg.sender) {}
    
    // Called on deployment

    /**
    @dev tem happi
    */

    function temHappi(address tem) external onlyOwner{
        _mint(tem, Items.GOLD, 1_000, "");
        _mint(tem, Items.DAGEROUS_DAGER, 4, "");
        _mint(tem, Items.TEM_FAV_ITEM, 10, "");
    }

    /**
    @dev challenge supplier
    */

    function freeGold(address to, uint256 amount) external onlyOwner{
        _mint(to, Items.GOLD, amount, "");
    }
}
