// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC1155} from "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Holder} from "lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import  {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./iTems.sol";


contract TemU is Ownable,ERC1155Holder {

    struct Listing {
        uint256 id;
        address seller;
        uint256 itemId;
        uint256 quantity;
        uint256 price;
        bool active;
    }

    iTems public token;

    event newListing();
    event itemPurchased(uint256, address,uint256,uint256,uint256);

    uint64 public goldPrice;

    mapping(uint256 => Listing) public listings;
    
    uint256[] public listingsIds;

    constructor(address _token)  Ownable(msg.sender) {
        token = iTems(_token);
        goldPrice = 1_000_000_000;
    }

    function createListing(uint256 item_id, uint256 quantity, uint256 price) external {
        // Basic checks
        require(item_id >=0 && item_id < 3,"Item not found");
        require(quantity > 0, "Quantity must be greater than zero");
        require(price > 0, "Price must be greater than zero");

        uint256 listingId = uint256(keccak256(abi.encodePacked(msg.sender, item_id)));
        for (uint256 i; i < listingsIds.length; i++){
            require(listingsIds[i] != listingId, "Only one per seller per item allowed");
        }

        // Make sure we are allowed to move funds
        require(token.balanceOf(msg.sender, item_id) >= quantity,"Insufficient balance");
        require(token.isApprovedForAll(msg.sender, address(this)),"This marketplace is not approved");

        listings[listingId] = Listing(listingId, msg.sender, item_id, quantity, price,true);
        listingsIds.push(listingId);

        emit newListing();

    }

    function purchaseItem(uint256 listingIdToPurchase, uint256 qunatityToPurchase) external {
        Listing storage listing = listings[listingIdToPurchase];
        // Basic checks
        require(listing.active, "Listing not active");
        require(listing.quantity >= qunatityToPurchase, "Not enough quantity in listing");
        require(qunatityToPurchase > 0, "Quantity must be greater than zero");

        uint256 totalGoldCost = listing.price * qunatityToPurchase;
        require(token.balanceOf(msg.sender, Items.GOLD) >= totalGoldCost, "Insufficient GOLD balance");

        token.safeTransferFrom(listing.seller, msg.sender, listing.itemId, qunatityToPurchase, "");

        // Update listing quantity
        if (listing.quantity > 0) {
            listing.quantity -= qunatityToPurchase;
        }

        if (listing.quantity == 0) {
            listing.active = false;
            uint256 indexToRemove = type(uint256).max;
            for (uint256 i = 0; i < listingsIds.length; i++) {
                if (listingsIds[i] == listingIdToPurchase) {
                    indexToRemove = i;
                    break;
                }
            }
            if (indexToRemove != type(uint256).max && listingsIds.length > 0) {
                listingsIds[indexToRemove] = listingsIds[listingsIds.length - 1];
                listingsIds.pop();
            }
        }

        token.safeTransferFrom(msg.sender, listing.seller, Items.GOLD, totalGoldCost, "");

        emit itemPurchased(listingIdToPurchase, msg.sender, listing.itemId, qunatityToPurchase, totalGoldCost);
    }

    function showListings() external view returns (Listing[] memory){
        Listing[] memory allListings = new Listing[](listingsIds.length);
        for (uint256 i = 0; i < listingsIds.length; i++){
            allListings[i] = listings[listingsIds[i]];
        }

        return allListings;
    }

    function buyGold(uint64 goldToBuy) external payable {
        require(goldToBuy > 0, "Zero gold not allowed");
        require(msg.value > 0, "Zero ether not allowed");

        unchecked { 
            //overflow
            uint64 ethRequired = goldToBuy * goldPrice; 

            require(msg.value >= ethRequired, "Insufficient Ether sent");
            require(token.balanceOf(address(this), Items.GOLD) >= goldToBuy, "Try again later");

            // Refund any excess ETH
            if (msg.value > ethRequired) {
                payable(msg.sender).transfer(msg.value - ethRequired);
            }
        }

        token.safeTransferFrom(address(this), msg.sender, Items.GOLD, goldToBuy, "");

    }
}
