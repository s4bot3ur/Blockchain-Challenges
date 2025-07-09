pragma solidity ^0.6.0;

import {KittyKittyBank} from "./KittyKittyBank.sol";


contract Setup{
    KittyKittyBank public immutable kittyBank;

    constructor()payable{
        kittyBank=new KittyKittyBank{value:msg.value}();
    }

    function isSolved()public returns (bool){
        return address(kittyBank).balance==0;
    }

}