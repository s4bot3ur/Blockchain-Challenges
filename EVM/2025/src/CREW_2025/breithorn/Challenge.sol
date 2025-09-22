// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./VaultFactory.sol";
import "./Vault.sol";

import "./Token.sol";


contract Challenge {

    address constant public PLAYER = 0x915f794B36Fd328D362445e3BD66ae4f3A894389;

    VaultFactory public vaultFactory;
    bool public solved;
    constructor() payable {
        vaultFactory = new VaultFactory(PLAYER, address(this));
    }

    function solve() public returns(bool) {

        Vault vault = Vault(vaultFactory.vaultAt(0));
        if(address(vault) == address(0)) return false;

        // helper function to simulate the challenge token minting
        Token(address(vault.asset())).mintToChallenge();

        vault.asset().approve(address(vault), type(uint256).max);
        vault.deposit(800 ether, address(this));

        if(vault.balanceOf(address(this)) == 0) {
            solved=true;
            return true;
        }
        return false;
    }

    function isSolved()public view returns(bool){
        return solved;
    }

    //@note this is original isSolved() function. Iam changing the format to make it uniform for all challs
    /*
    function isSolved() public returns(bool) {

        Vault vault = Vault(vaultFactory.vaultAt(0));
        if(address(vault) == address(0)) return false;

        // helper function to simulate the challenge token minting
        Token(address(vault.asset())).mintToChallenge();

        vault.asset().approve(address(vault), type(uint256).max);
        vault.deposit(800 ether, address(this));

        if(vault.balanceOf(address(this)) == 0) return true;

        return false;
    }
    */
}