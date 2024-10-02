# Writeup for Dex

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

This contract utilizes a library to store two different times for two different timezones. The constructor creates two instances of the library for each time to be stored.

The goal of this level is for you to claim ownership of the instance you are given.

Things that might help

- Look into Solidity's documentation on the delegatecall low-level function, how it works, how it can be used to delegate operations to on-chain libraries, and what implications it has on execution scope.
- Understand what it means for delegatecall to be context-preserving.
- Understand how storage variables are stored and accessed.
- Understand how casting works between different data types.

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

contract Dex is Ownable {
address public token1;
address public token2;

    constructor() {}

    function setTokens(address _token1, address _token2) public onlyOwner {
        token1 = _token1;
        token2 = _token2;
    }

    function addLiquidity(address token_address, uint256 amount) public onlyOwner {
        IERC20(token_address).transferFrom(msg.sender, address(this), amount);
    }

    function swap(address from, address to, uint256 amount) public {
        require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
        require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
        uint256 swapAmount = getSwapPrice(from, to, amount);
        IERC20(from).transferFrom(msg.sender, address(this), amount);
        IERC20(to).approve(address(this), swapAmount);
        IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
    }

    function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
        return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
    }

    function approve(address spender, uint256 amount) public {
        SwappableToken(token1).approve(msg.sender, spender, amount);
        SwappableToken(token2).approve(msg.sender, spender, amount);
    }

    function balanceOf(address token, address account) public view returns (uint256) {
        return IERC20(token).balanceOf(account);
    }

}

contract SwappableToken is ERC20 {
address private \_dex;

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

They gave us a DEX contract. DEX refers to Decentralized Exchange where we can do financial ativities such as swapping tokens.

The contract inherits Ownable contract. Click [here](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol) to view the Ownable contract.

The `Ownable` contract has the state variable `owner` and it is initialized to `msg.sender` in `constructor()`. That mean's owner will be the person one who is deploying the `Dex` contract.

The `Dex` contract has two state variables `token1` and `token2`. Both the state variables are of type address.

```solidity
function setTokens(address \_token1, address \_token2) public onlyOwner {
token1 = \_token1;
token2 = \_token2;
}
```

This function will set the address of `token1` and `token2`.

```solidity
function addLiquidity(address token_address, uint256 amount) public onlyOwner {
    IERC20(token_address).transferFrom(msg.sender, address(this), amount);
}
```

The above function `addLiquidity()` will take two arguments of type **address** (token_address) and **uint256** (amount) as input. Basically the function will add more tokens of the token_address passed during the call. It can be only called by owner because it has `onlyOwner` modifier.

Since the `Dex` contract is a Decentralized Exchange used for swapping tokens, there should be at least two tokens accepted in the Dex contract. Suppose the `Dex` contract accepts two tokens, `token1` and `token2`, for exchange. If people swap `token2` for `token1` and all of `token1` is depleted in the `Dex` contract, it can no longer facilitate swaps. Therefore, when one of the tokens becomes very scarce, the owner will add more of the scarce token to ensure the `Dex` continues to function.

```solidity
function swap(address from, address to, uint256 amount) public {
    require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
    require(IERC20(from).balanceOf(msg.sender) >= amount, "Not enough to swap");
    uint256 swapAmount = getSwapPrice(from, to, amount);
    IERC20(from).transferFrom(msg.sender, address(this), amount);
    IERC20(to).approve(address(this), swapAmount);
    IERC20(to).transferFrom(address(this), msg.sender, swapAmount);
}
```

The above function `swap()` will take three arguments of type **address** (from), **address** (to), **uint256** (amount) as input. In the logic part first it will check whether the swapping is done between the `allowed tokens` (token1 and token2) or not. If the users use any other token for swapping which is not allowed by `Dex` contract then it will revert. Then it checks whether the user is having the tokens they are swapping or not. Then it will get the swapAmount using the function `getSwapPrice()` .

`swapAmount` is basically when user wants to swaps `token1` with `token2` they will send `token1` to `Dex` contract and `Dex` contract will send the user `token2`. But the number of tokens sent by user and the number of tokens sent by Dex contract won't be same because the price of `token1` and `token2` might not be same. Based on the price difference `getSwapPrice()` will return the number of `token2` user will get for swapping with toke`n1.

```solidity
function getSwapPrice(address from, address to, uint256 amount) public view returns (uint256) {
    return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
}
```

The above function `getSwapPrice()` will return then number of tokens user will get for swapping with another type of tokens.

```solidity
function approve(address spender, uint256 amount) public {
    SwappableToken(token1).approve(msg.sender, spender, amount);
    SwappableToken(token2).approve(msg.sender, spender, amount);
}
```

The function `approve()` takes two arguments: an **address** (spender) and a **uint256** (amount). The function calls the approve function in the SwappableToken contract. SwappableToken is a basic ERC20 contract. The approve function in the Dex contract calls the approve function in the SwappableToken contract, passing `msg.sender`, `spender`, and `amount` as arguments. This allows the `spender` to spend the specified `amount` on behalf of `msg.sender` for both the tokens.

```solidity
function balanceOf(address token, address account) public view returns (uint256) {
    return IERC20(token).balanceOf(account);
}
```

The above function `balanceOf()` will take two arguments of type **address**(token) and **address**(account) as input . The function will return the balance of the account in token passed.

</details>

### Key Concepts To Learn

Before starting to solve this challenge we need to make sure that we have a good understanding of ERC20 tokens.

I have explained about ERC20 contract in the Token challenge. Click [here](../Token/WriteUp.md) to open the WriteUp for that challenge.

### Exploit

In the challenge we was given 10 tokens of token1 and token2 and the Dex contract is having 100 tokens of token1 and token2. Our task is drain one of the token balance of Dex contract.

After looking into the Dex contract, I felt like everything is working fine except the getSwapPrice() function. If we see the getSwapPrice() function, we can find that the logic the function uses is not correct to get the swapAmount.

The formulae for calculating swapAmount is `((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)))`.

When we swap our 10 token1 for token2 we will get 10 token2 based on the getSwapPrice() function. Now we have 0 token1 and 20 token2. The next time when we swap our 20 token2 for token1 we will get 24 token1 . The next time when we swap 24 token1 for token2 we will get 30 tokens. So on it will continue. Check the below image to view how swapAmount is manipulated in each swap.

<p align="center">
  <img src="img/img1.png" />
</p>

- First we will swap `10 token1` and we get `10 token2`. swapAmount is `(10* 100/100)=10` so we get `10 token2`. After this swap Dex contract has `110 token1` and `90 token2`.

- For second time we swap our `20 token2` and we will get `24 token1`. swapAmount is `(20* 110/90)=24`. So we get `24 token1`. After this swap Dex contract has `86 token1` and `110 token2`.
- For the third time we swap our `24 token1` and we will get `30 token2`. swapAmount is `(24*110/86)=30`. So we get `30 token2` After this swap Dex contract has `110 token1` and `80 token2`.
- For the fourth time we swap our `30 token2` and we will get `41 token1`. swapAmount is `(30 *110/80)=41`. So we will get 41 tokens1. After this swap, Dex contract has 69 token1 and 110 token2.
- For the fifth time we swap our `41 token1` and we will get `65 token2`. swapAmount is `(41*110/69)=65`. So we will get `65 token2`. After this swap Dex contract has `110 token1` and `45 token2`.
- For the sixth time we swap only `45 token2` and we will get `110 token1` . swapAmount is `(45*110/45)=110`. So we will get `110 token1`. After this swap, Dex contract has `0 token1` and `90 token2`.

During the sixth swap, we only swap `45 token2` because if we swap more than 45 then swapAmount will be more than the Dex contract balance. Suppose we swap `50 token2` then we will get swapAmount as `(50*110/45)=122` `122 token1` which means in return we will get `122 token2` but the Dex contract only has `110 token2`. So it will revert if we try to swap more than `45 token2` in the last call.

Now lets exploit the contract.

Before calling swap() function we need to make sure that we have allowed the Dex contract to send tokens on our behalf because when we swap token1 for token2 we are sending our token1 to the Dex contract and the Dex contract will send us token2. But we are not directly transfering the ether instead the Dex contract uses transferFrom() to receive our tokens.

`IERC20(from).transferFrom(msg.sender, address(this), amount)` you can find this line in swap() function.

Now it's time to open the console. Open **Dex** challenge and enter `ctrl`+`shift`+`j` to open the console.

```javascript
> await contract.approve(contract.address,1000)
```

```javascript
> token1=await contract.token1()
> token2=await contract.token2()
```

```javascript
> await contract.swap(token1,token2,10)
```

```javascript
> await contract.swap(token2,token1,20)
```

```javascript
> await contract.swap(token1,token2,24)
```

```javascript
> await contract.swap(token2,token1,30)
```

```javascript
> await contract.swap(token1,token2,41)
```

```javascript
> await contract.swap(token2,token1,45)
```

Once the above calls are done the Dex contracts token1 balance will be zero. We can verify it by the following.

```javascript
> (await contract.balanceOf(token1,contract.address)).toString()
```

Now you can submit the level instance.

<p style="text-align:center;">***Hope you enjoyed this write-up. Keep on hacking and learning!***</p>

### Key Takeaways

1. **Single Source Data Vulnerability**: Relying on a single source for prices or any data in smart contracts introduces a significant attack vector. An attacker with substantial capital can manipulate the price, leading to incorrect data being used by dependent applications.

2. **Decentralization vs. Centralization**: While the exchange itself may be decentralized, the asset's price can still be centralized if it comes from a single DEX. This centralization makes it susceptible to manipulation.

3. **Mitigation through Multiple Sources**: Using tokens that represent real assets, which have exchange pairs across multiple DEXes and networks, can mitigate the risk. This diversification reduces the impact of any single DEX targeted by an attack.
