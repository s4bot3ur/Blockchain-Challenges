# Writeup for Naught Coin

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

NaughtCoin is an ERC20 token and you're already holding all of them. The catch is that you'll only be able to transfer them after a 10-year lockout period. Can you figure out how to get them out to another address so that you can transfer them freely? Complete this level by getting your token balance to 0.

Things that might help

- The ERC20 Spec
- The OpenZeppelin codebase

### Contract Explanation

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

<details>
<summary>Click to view the source contract and contract explanation</summary>

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin';
    // string public constant symbol = '0x0';
    // uint public constant decimals = 18;
    uint256 public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;

    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals()));
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        _mint(player, INITIAL_SUPPLY);
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}

```

The `NaughtCoin` contract inherits the `ERC20` contract, which provides a standard implementation for creating tokens and assets. Before the introduction of the ERC20 token standard, different crypto assets or tokens used different logic, making it difficult to achieve interoperability between them. The ERC20 standard defines a set of functions that every token must have, enabling seamless interoperability between different tokens. This standardization has greatly simplified token transfers and interactions within the Ethereum ecosystem.

Click the below links to read more about the ERC20 standard.

1. [ERC-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)
2. [ERC20 Token standard Basics](https://medium.com/@ragunath12/erc20-token-standard-basics-beginners-guide-9d2780099666#:~:text=ERC%2D20%20stands%20for%20Ethereum,based%20on%20the%20Ethereum%20blockchain.)
3. [ERC20 Token Standard Explained](https://www.youtube.com/watch?v=acYcOs7HOls) _Must Watch_
4. [ERC20 Contract](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)

I assume you have gone through these resources and I will proceed.

```solidity
constructor(address _player) ERC20("NaughtCoin", "0x0") {
    player = _player;
    INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals()));
    _mint(player, INITIAL_SUPPLY);
    emit Transfer(address(0), player, INITIAL_SUPPLY);
}
```

During the deployment of the `NaughtCoin` contract, the constructor will be called. The constructor takes an argument of type address as input. The `ERC20` contract constructor takes two arguments as input: the token name and the token symbol. For the ERC20 contract constructor, "NaughtCoin" and "0x0" are passed as arguments. For the NaughtCoin contract, the address of the player (our address) is passed as an argument.

The `constructor()` will set the player to the address passed as an argument. `INITIAL_SUPPLY` is the initial supply of the tokens, which is set to `1000000 * (10 ** uint256(decimals()))`. The `decimals()` function in the `ERC20` contract returns `18`.

Then it will mint the initial supply of tokens to the player. Minting is the process of creating or issuing tokens. Finally, it will emit the Transfer event in the `ERC20` contract.

```solidity
modifier lockTokens() {
    if (msg.sender == player) {
        require(block.timestamp > timeLock);
        _;
    } else {
        _;
    }
}
```

The `lockTokens()` is a modifier that restricts the transfer of tokens owned by the player for 10 years.

```solidity
function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
    super.transfer(_to, _value);
}
```

The `transfer()` function takes two arguments: the recipient's address and the amount of tokens to transfer. It then executes the `lockTokens()` modifier. If the modifier check passes successfully, the function will invoke the `transfer()` function in the `ERC20` contract.

</details>

### Exploit

Our goal is to transfer all the tokens given to us and make our balance zero.

However, when we check the `transfer()` function in the `NaughtCoin` contract, it only allows us to transfer our tokens after a 10-year lockout period. Waiting for 10 years to transfer all our tokens and solve this challenge is not feasible. Therefore, we need to find a different method to transfer our tokens.

If we examine the ERC20 contract, we can find that there are two ways of transferring tokens. One method is directly transferring tokens by the owner, and the other method is allowing another account to spend tokens on behalf of the owner. If you haven't reviewed the ERC20 contract, I strongly recommend doing so. You can find the contract [here](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol).

```
function transfer(address to, uint256 value) public virtual returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, value);
    return true;
}

function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, value);
    _transfer(from, to, value);
    return true;
}

function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
 uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
        if (currentAllowance < value) {
            revert ERC20InsufficientAllowance(spender, currentAllowance, value);
        }
        unchecked {
            _approve(owner, spender, currentAllowance - value, false);
        }
    }
}

```

There are two ways of transferring tokens. However, if we look at the second method, there is a function called `_spendAllowance()`. The `_spendAllowance()` function checks whether the owner has allowed another account to spend tokens on their behalf. If there is no allowance, it will revert.

If we check our `NaughtCoin` contract, we can see that it has only overridden and implemented the `transfer()` function. This means that only the `transfer()` function has the time lock. However, if we send tokens using `transferFrom()`, we can instantly send the tokens without any restrictions. But before we can do that, we need to allow another account to spend tokens on our behalf, and then they can transfer the tokens to any other person. We can even approve our externally owned account and directly use `transferFrom()`.

```solidity
function approve(address spender, uint256 value) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, value);
    return true;
}
```

The `approve()` function approves the spender to spend a certain amount of tokens on behalf of the owner. Now that we know what to do, let's exploit this contract!

Now it's time to open the console. Open the Naught Coin challenge and press `Ctrl`+`Shift`+`J` to open the console. Enter the following commands:

```javascript
> await contract.approve(player, contract.INITIAL_SUPPLY)
```

```javascript
> await contract.transferFrom(player, address(0), contract.INITIAL_SUPPLY)
```

```javascript
> await contract.balanceOf(player)
```

If all the calls are successful, the balance will return zero, and now you can submit the level instance.

### Key Takeaways

If we are implementing a normal token contract that works the same for everyone, we can directly inherit the ERC20 contract and use all its functions without overriding them.

However, if we are implementing a token contract that restricts certain users from withdrawing or depositing tokens, we need to override all the functions in the ERC20 contract and implement the restriction logic in those functions. If we don't override the functions then whenever the user calls the function it will be directly called in the ERC20 contract and it will be executed normally because in the ERC20 standard contract there won't be any restrictions to anyone.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
