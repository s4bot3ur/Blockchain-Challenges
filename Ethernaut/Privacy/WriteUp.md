# Writeup for Privacy

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. For each challenge, a contract will be deployed, and an instance will be provided. Your task is to interact with the contract and exploit its vulnerabilities. Don't worry if you are new to Solidity and have never deployed a smart contract. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

The creator of this contract was careful enough to protect the sensitive areas of its storage.

Unlock this contract to beat the level.

Things that might help:

- Understanding how storage works
- Understanding how parameter parsing works
- Understanding how casting works

Tips:

Remember that metamask is just a commodity. Use another tool if it is presenting problems. Advanced gameplay could involve using remix, or your web3 provider.

### Contract Explanation

Click [here](./src/contracts/Privacy.sol) to view the contract.

If you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.
The contract has six state variables named `locked`, `ID`, `flattening`, `denomination`, `awkwardness`, and `data`.

The state variable `locked` is a **boolean** type and initialized to true. `ID` is a **uint256** which is initialized with `block.timestamp`. `flattening` is a **uint8** and it is initialized with `10`. `denomination` is a **uint8** and it is initialized with `255`. `awkwardness` is a **uint16** and it is initialized with `block.timestamp` converted into **uint16**. `data` is a **bytes32** array of length 3.

At this point, `block.timestamp` will return a 4-byte number. The `awkwardness` variable stores 2 bytes of `block.timestamp`, which means out of 4 bytes, only 2 bytes will be stored in awkwardness, i.e., the last two bytes will be stored in awkwardness.

If `block.timestamp` is **0x0000000000000000000000000000000000000000000000000000000066f6e2d4**, the bytes2 of `block.timestamp` will return **0xe2d4**.

```solidity
constructor(bytes32[3] memory _data) {
    data = _data;
}
```

The constructor takes a **bytes32** array of length 3 as an argument. Then this array is initialized to the `data` variable.

```solidity
function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
}
```

The function `unlock()` is a public function that takes an argument of type **bytes16** as input. Then it compares the **bytes16** passed and the **bytes16** of the **3rd element** in the `data` array. If both are the same, then `locked` will become false.

### Key Concepts to Understand

Please go through the `Vault` write-up if you don't know anything about storage layout because I won't be explaining the storage layout here.

In the `Vault` challenge _WriteUp_, I have clearly explained the basics of storage slots. [Click here](./../Vault/WriteUp.md) to open the _WriteUp_ of `Vault`.

Now I will explain how arrays are stored in EVM. There are two types of arrays in Solidity: `fixedArray` and `dynamicArray`. The two types of arrays will be stored in EVM using different methods. Check out the example below to learn how it works.

```solidity

contract Array_Storage_Layout{
    uint256 private num=10;
    bool private a=true;
    uint256[3] private num_fixedArray=[1,2,3];
    uint256[] private num_dynamicArray=[1,2,3];
    uint128 private num_1=100;

    function addElement_num_dynamicArray(uint256 _num)public{
        num_dynamicArray.push(_num);
    }
}

```

Storage slot 0 contains the variable `num`, `slot 1` contains the variable `a`.

Now if we check `slot 2`, it should store the `num_fixedArray`, but since it is a **fixed array**, each element of the array is stored in one slot. Which means `slot 2` contains `num_fixedArray[0]`, `slot 3` contains `num_fixedArray[1]`, and `slot 4` contains `num_fixedArray[2]`.

Now if we check the next variable, it is `num_dynamicArray`, which is a **dynamic array**, meaning its length is not fixed. Since it is a **dynamic array**, if we assign `num_dynamicArray[0]` to `slot 5`, `num_dynamicArray[1]` to `slot 6`, and `num_dynamicArray[3]` to `slot 7`, then the last variable `num_1` will be assigned to `slot 8`, and this will be the last slot since there are no more state variables.

However the above is not the correct method because when we call the `addElement_num_dynamicArray()` function, it will add an element to the `num_dynamicArray` array. According to the storage slots of the array, the latest value should be stored in `slot 8` because the last element of `num_dynamicArray` is stored in `slot 7`. But `slot 8` is already assigned with `num_1` before calling the function itself. This will lead to storage collisions.

So instead of storing the first element of the array in the slot number of the state variable, i.e., instead of storing the first element of `num_dynamicArray` in `slot 5`, it will store the length of `num_dynamicArray`. Then the first element of `num_dynamicArray` is stored at the keccak hash of `slot 5` and consecutive elements in consecutive slots.

The storage layout for the above contract will be as follows:

<p align="center">
  <img src="img/img1.png" />
</p>

### Exploit

If you are directly solving this challenge without solving `Vault`, I recommend you to go solve `Vault` first and then solve this challenge.

The challenge is to make the `locked` variable false. If we see the contract, the variable `locked` is set to false only in the `unlock()` function. We can call the `unlock()` function, but we need to pass the correct key as an argument.

In the `unlock()` function, it compares the key with the third element in the `data` array. The `data` array is a private array, which means other contracts cannot access the `data` array.

We know that even if the state variable is marked as private, we cannot get its value by interacting with the contract, but we can get the private variables by going through the storage layout of the contract. This is possible only due to the transparency of the blockchain. The state variables are stored on EVM, which is part of the blockchain. The EVM is responsible for executing smart contracts and maintaining the state of the blockchain, including the storage of state variables.

The storage layout of the given contract is as follows:

<p align="center">
  <img src="img/img2.png" />
</p>

Now it's time to open the console. Open the **Privacy** challenge and enter `ctrl`+`shift`+`j` to open the console.

```javascript
> await web3.eth.getStorageAt("contract.address",0)
> await web3.eth.getStorageAt("contract.address",1)
> await web3.eth.getStorageAt("contract.address",2)
> await web3.eth.getStorageAt("contract.address",3)
> await web3.eth.getStorageAt("contract.address",4)
> await web3.eth.getStorageAt("contract.address",5)
```

Try out all these and check whether they exactly match the layout I have given.

Now we need `data[2]`, which is stored in `slot 5`. The value is `0xb86abc73432c0400110ad803960273e6cc6a889bb99e10ca45ca72c7e10d3ed6`. If we see the value, it is of size **32 bytes**, but in the `unlock()` function, it is comparing the key with **16 bytes** of `data[2]`. So the 32-byte key is explicitly converted to **bytes 16**.

In Solidity, when a **bytes 32** is converted to **bytes 16**, it only takes the first 16 bytes. In our case, the bytes 32 is `0xb86abc73432c0400110ad803960273e6`, and when it is typecasted to bytes 16, the output will be `0xb86abc73432c0400110ad803960273e6`.

Now we need to pass `0xb86abc73432c0400110ad803960273e6` as an argument to `unlock()`. Once we pass the value, the `locked` variable will become false.

```javascript
> await contract.unlock("0xb86abc73432c0400110ad803960273e6")

```

Now, before submitting, we need to verify whether `locked` is false or not.

```javascript
> await contract.locked()
```

If `locked` returns false, then the challenge will be solved. You can submit the instance now.

### Key Takeaways

We should not store any important data in smart contracts. Even though the state variables view is private, they can be accessed by anyone.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
