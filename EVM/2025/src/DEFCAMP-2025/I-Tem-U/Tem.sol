// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Holder} from "lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import  {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


import "./TemU.sol";
import "./iTems.sol";

contract Tem is Ownable{

    iTems token;
    TemU marketplace;

    constructor(address _token, address _marketplace) Ownable(msg.sender){
        token = iTems(_token);
        marketplace = TemU(_marketplace);

    }

    function sellTem() external onlyOwner{
        token.setApprovalForAll(address(marketplace), true);
        marketplace.createListing(Items.TEM_FAV_ITEM, 1, 1e10);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual  returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}