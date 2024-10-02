# Writeup for Alien Codex

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

Hello hacker, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

You've uncovered an Alien contract. Claim ownership to complete the level.

Things that might help:

- Understanding how array storage works
- Understanding ABI specifications
- Using a very underhanded approach

### Contract Explanation

The contract `AlienCodex` inherits a contract named `Ownable` with a version of `0.5.0`. The `AlienCodex` contract has two state variables: `contact`, which is a boolean, and `codex`, which is a dynamic array of type `bytes32`.

<details>
<summary>Click to view the source contract and contract explanation</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "../helpers/Ownable-05.sol";

contract AlienCodex is Ownable {
    bool public contact;
    bytes32[] public codex;

    modifier contacted() {
        assert(contact);
        _;
    }

    function makeContact() public {
        contact = true;
    }

    function record(bytes32 _content) public contacted {
        codex.push(_content);
    }

    function retract() public contacted {
        codex.length--;
    }

    function revise(uint256 i, bytes32 _content) public contacted {
        codex[i] = _content;
    }
}

```

The contract AlienCodex inherits a contract named Ownable. The version of the Ownable contract is 0.5.0. Click [here](https://github.com/OpenZeppelin/openzeppelin-test-helpers/blob/master/contracts/Ownable.sol) to view the ownable contract.

The contract AlienCodex has two state variables: `contact`, which is a boolean, and `codex`, which is an array of type `bytes32`.

```solidity
modifier contacted() {
    assert(contact);
    _;
}
```

This modifier checks whether `contact` returns true or not. If `contact` returns true, the modifier will be passed; otherwise, it will revert.

```solidity
function makeContact() public {
    contact = true;
}
```

The function `makeContact()` is a public function that sets `contact` to `true`.

```solidity
function record(bytes32 _content) public contacted {
    codex.push(_content);
}
```

The function `record()` is a public function that takes an argument of type `bytes32` as input. It adds the `_content` to the `codex` array.

```solidity
function retract() public contacted {
    codex.length--;
}
```

The function `retract()` is a public function. It first executes the `contacted` modifier. If the modifier passes successfully, it will decrement the array length, effectively removing the last element from the array.

```solidity
function revise(uint256 i, bytes32 _content) public contacted {
    codex[i] = _content;
}
```

The function `revise()` is a public function that takes arguments of type `uint256` (`i`) and `bytes32` (`_content`) as input. The function updates the value at index `i` in the `codex` array with the `_content`. If the array size is less than the index passed, it will revert.

</details>

### Key Concepts To Learn

I have already discussed how array storage works in the [Privacy](../Privacy/WriteUp.md) challenge. I have explained about storage slots of static and dynamic arrays along with examples.

Refer to that challenge to learn how storage slots work.

### Exploit

Now let's try to crack this challenge.

Our task is to become the owner of this contract. The logic for managing ownership is in the `Ownable` contract. But we can't find any exploit there. However, if we see the compiler version of the `AlienCodex` contract, it is `0.5.0`. We know that every contract whose compiler version is less than `0.8.0` and does not have the `SafeMath` library is vulnerable to `overflow` and `underflow` exploits.

Now let's understand the storage layout of the contract.

Since the `AlienCodex` contract is inheriting the `Ownable` contract, the storage layout starts with the `Ownable` contract's state variables. When we open the `Ownable` contract, we can observe that there is only one state variable, which is the address of the **owner**.

So the **owner** will be in `slot0`.

If we check the `AlienCodex` contract, there are two state variables. One is a boolean named `contact`, and the other one is a dynamic array named `codex`.

Since the variable `owner` size is only 20 bytes, there are 12 bytes left to be filled in `slot0`. If the next state variable size is less than 12 bytes, then the next variable will also be stored in the same `slot0`.

Since a **bool** is only one byte, `contact` will be stored in `slot0` itself.

The next state variable in `AlienCodex` is a dynamic array, so it will start in the next slot. Since it is a dynamic array, the length of the array will be stored in `slot1`, and the first element of the array will be stored at `keccak(abi.encode(1))`. The second element will be stored at `keccak(abi.encode(1)) + 1`, and so on.

```solidity
function retract() public contacted {
    codex.length--;
}
```

If we look at the `retract()` function, we can see that it is decrementing the size of the `codex` array by removing the last element.

But what if the array size is zero and then we call `retract()`? Then it will reduce the size by 1, which leads to underflow. If we call `retract()` when the array size is zero, it leads to underflow, and the array size becomes `2**256-1`.

In Solidity, every state variable is stored in the EVM in the form of storage slots. There are a total of `2**256-1` storage slots for a contract. Now, if we compare the latest array size (`2**256-1`) and the number of storage slots, we can conclude that both are of the same size, which means the array is occupying the entire storage layout of that contract.

Even if there are other variables other than the `codex` array, they will also be stored in one of the `2**256-1` slots. That means if there is a state variable stored in the storage layout of the contract and if we change all the elements of the new array, which is of size `2**256-1`, then the state variable is overwritten. This is a huge vulnerability.

Our task is to claim ownership. So we need to overwrite the `owner` variable, which is stored at `slot0`.

Now, when we call `retract()`, the array size will become `2**256-1`, and the first element of the array will be stored at `keccak256(abi.encode(1))`. Since the owner is in `slot0`, we need to overwrite `slot0`. Technically, slot zero is `(2**256-1)+1`, where `2**256-1` is the last storage slot of the contract, and when we add 1 to the max size of the array, it will lead to an overflow.

The first element of the array is stored at `keccak256(abi.encode(1))`. The second element will be stored at `keccak256(abi.encode(1)) + 1`, and so on. If we know the index of the last storage slot, then we can easily change the value at the zeroth storage slot by causing an overflow.

Now we need to create an equation such that `keccak256(abi.encode(1))+x=(2**256-1)`. This means that when we add some `x` to the storage slot of the first element of the array, the sum should become `2**256-1`, which is the last slot of a contract.

From the above equation, we can write `x=(2**256-1)-keccak256(abi.encode(1))`.

`x` will be the index at which the last slot value is stored. If we add 1 to it, it will lead to an `overflow`, and it will be the place where the value of the `zeroth slot` will be stored. Now we can assign the value whatever we want there.

So now our target index is `x+1=(2**256-1)-keccak256(abi.encode(1))+1`.

Below is the exploit contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import {AlienCodex} from "./AlienCodex.sol";

contract ExploitAlienCodex {
    AlienCodex alienCodex;

    constructor(address _addr) public {
        alienCodex = AlienCodex(_addr);
    }

    function Exploit() public {
        alienCodex.makeContact();
        alienCodex.retract();
        uint256 index = (2**256-1)-uint256(keccak256(abi.encode(1)))+1;
        alienCodex.revise(index, bytes32(uint256(uint160(msg.sender))));
    }

}

```

Once you call the exploit function, the challenge will be solved.

### Key Takeaways

- The `retract()` function can be exploited to underflow the `codex` array and overwrite the storage layout of the contract.
- By calculating the index of the last storage slot and causing an overflow, we can overwrite the value of the `owner` variable and claim ownership of the contract.
- We should we careful while using the solidity compiler version's less than 0.8.0.
