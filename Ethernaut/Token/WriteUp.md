# Writeup for Token

- Hello hacker, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity well. For each challenge, they will deploy the contract and provide us with the instance of that contract. Our task is to interact with the contract and exploit it. Don't worry if you are completely new to Solidity and have never deployed a smart contract before. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge

- The goal of this level is for you to hack the basic token contract below.
- You are given 20 tokens to start with, and you will beat the level if you somehow manage to get your hands on any additional tokens, preferably a very large amount of tokens.

### Contract Explanation

- Click [here](./src/contracts/Token.sol) to view the contract.

- If you feel like you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.

- The contract has two state variables: `balances` and `totalSupply`. `balances` is a mapping of address to tokens, and `totalSupply` is the total number of tokens available.

```solidity
    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }
```

- In the above code snippet, the constructor takes an argument `_initialSupply` and sets the balances of `msg.sender` and `totalSupply` to `_initialSupply`.

```solidity
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
```

- The function `transfer()` is a public function that takes two arguments address and amount to transfer as input, and returns `true` if the transfer is successful.

- First, it checks if the balance of `msg.sender` is more than the value they are transferring. If yes, it will continue executing the next lines; otherwise, it will revert.

- If the require statement is satisfied, it will reduce the balance of `msg.sender` and increase the balance of `_to`, and then return `true`.

```solidity
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
```

- The function `balanceOf()` is a public function that takes an address as input and returns the balance of that address.

### Exploit

- The only function in the contract that changes the state of the contract is the `transfer()` function. So we need to look at the `transfer()` function for any loops.

- If we check the solidity compiler version, it is ^0.6.0, which means any version more than 0.6.0 is supported.

- Solidity versions less than 0.8.0 don't implicitly check for overflow and underflow errors. Let me give you a basic example of what overflow and underflow are. Observe the following contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract overflow_underflow{
    uint8 overflow=255;
    uint8 underflow=0;

    function increment()public{
        overflow++;
    }

    function decrement()public{
        underflow--;
    }

}
```

- The above contract is a good example to understand overflows and underflows. The state variable `overflow` is set to 255, and the state variable `underflow` is set to 0.

- `uint8` technically refers to 8 bits, which means it can store a maximum value of 255. If we increase the value of the variable after 255, it will start from zero again. In the above contract, if we call `increment()` once, then `overflow` will be set to zero. If we call it again, it will be set to 1, and so on.

- The minimum value of `uint8` is 0. But if we decrease a `uint8` variable after zero, it will become 255. In the above contract, if we call `decrement()` once, then `underflow` is set to 255. If we call it again, `underflow` will be set to 254, and so on.

- For solidity versions greater than 0.8.0, overflow and underflows are implicitly handled. But for solidity versions less than 0.8.0, we need to explicitly handle the overflows and underflows.

- There is a library named SafeMath to handle overflows and underflows for versions less than 0.8.0.

- Initially, we were given 20 tokens. If we observe, when we transfer, it reduces our balance. If we transfer 20 tokens, we will have 0 tokens. But if we transfer 21 tokens, an underflow will occur, and our balance will be set to 2^255 - 1.

- The require statement is also passed because `balances[msg.sender]` will return 20, and we are transferring `21`. So again, an underflow will occur, and the value returned will be greater than 0.

- Now it's time to open the console. Open the **Token** challenge and press `ctrl`+`shift`+`j` to open the console.

```javascript
> await contract.transfer("0x0000000000000000000000000000000000000000",21)
```

- That's it! Once the transaction is completed, you can submit the instance of this challenge.

### Key Takeaways

- For solidity versions less than 0.8.0, we need to explicitly handle the overflows and underflows. We can use the [SafeMath](https://github.com/aave/protocol-v2/blob/master/contracts/dependencies/openzeppelin/contracts/SafeMath.sol) library to overcome those.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
