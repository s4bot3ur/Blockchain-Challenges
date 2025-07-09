// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC20} from "./ERC20.sol";
import {Pool} from "./Pool.sol";

// Dummy WETH Token
contract DummyWETH is ERC20 {
    constructor(uint256 supply) ERC20("Dummy WETH", "WETH-D") {
        _mint(msg.sender, supply);
    }
}

// Dummy PUFETH Token
contract DummyPUFETH is ERC20 {
    constructor(uint256 supply) ERC20("Dummy PUFETH", "PUFETH-D") {
        _mint(msg.sender, supply);
    }
}

// Deployment Script
contract Setup {
    mapping(address => bool) public hasClaimedWETH;
    mapping(address => bool) public hasClaimedPUFETH;
    DummyWETH private wethToken = new DummyWETH(11 ether);
    DummyPUFETH private pufethToken= new DummyPUFETH(11 ether);
    Pool public immutable pool = new Pool(address(wethToken), address(pufethToken), 0);
    constructor() payable{
        // Deploy Dummy Tokens

         // Deploy Pool

        // Approve and add liquidity
        wethToken.approve(address(pool), 10 ether);
        pufethToken.approve(address(pool), 10 ether);

        pool.addLiquidity(10 ether, 10 ether);

        // Log addresses for reference
        // console.log("WETH-D Token:", address(wethToken));
        // console.log("PUFETH-D Token:", address(pufethToken));
        // console.log("Pool:", address(pool));

    }

    function claimWETH() external {
        require(!hasClaimedWETH[msg.sender], "Already claimed WETH");
        hasClaimedWETH[msg.sender] = true;
        wethToken.transfer(msg.sender,1 ether);

        
    }

    function claimPUFETH() external {
        require(!hasClaimedPUFETH[msg.sender], "Already claimed PUFETH");
        hasClaimedPUFETH[msg.sender] = true;
        pufethToken.transfer(msg.sender,1 ether);
    }

    function isSolved(address user) public view returns(bool){
        uint256 sharesHeldByPoolOwner = pool.balanceOf(address(this));
        uint256 sharesToWin = sharesHeldByPoolOwner/2;
        uint256 sharesHeldBySender = pool.balanceOf(user);

        return sharesHeldBySender > sharesToWin;
    }
}