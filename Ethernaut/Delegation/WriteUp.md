# Writeup for Delegation

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity well. For each challenge, they will deploy the contract and provide us with the instance of that contract. Our task is to interact with the contract and exploit it. Don't worry if you are completely new to Solidity and have never deployed a smart contract before. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge

- The goal of this level is for you to claim ownership of the instance you are given.

### Contract Explanation

Click [here](./src/contracts/Delegation.sol) to view the contract.

If you feel like you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.

Before getting started with contracts, I would like to explain the different types of calls in solidity. There are mainly three different calls.

1. Call
2. Static call
3. Delegate call

**1. Call:** Call is a low-level function in solidity it is used to call functions in smart contracts. Here is an example of how a call works.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A{
    uint256 public Favourite_Number1=10;
    uint256 public Favourite_Number2;
    uint256 public Favoruite_Number3;

    function increment_Favourite_Number1()public {
        Favourite_Number1++;
    }

    function set_Favourite_Number2(uint256 _num)public{
        Favourite_Number2=_num;
    }

    function set_Favourite_Number3(uint256 _num)public payable{
        require(msg.value >0.0001 ether);
        Favoruite_Number3=_num;
    }

}

contract B{
    A contract_A=A(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9);

    function call_increment_Favourite_Number1()public returns (bool){
        (bool success,)= address(contract_A).call(abi.encodeWithSignature("set_Favourite_Number1()"));
        require(success,"Call Failed");
        return true;
    }

    function call_set_Favourite_Number2()public returns(bool){
        (bool success,)= address(contract_A).call(abi.encodeWithSignature("set_Favourite_Number2(uint256)",10));
        require(success,"Call Failed");
        return true;
    }

    function call_set_Favourite_Number3()public payable returns(bool){
        (bool success,)= address(contract_A).call{value: 0.00012 ether}(abi.encodeWithSignature("set_Favourite_Number3(uint256)",11));
        require(success,"Call Failed");
        return true;
    }
}

// Address of contract A: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
// Address of contract B: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

Here we need to first deploy contract A and then deploy contract B. When you are trying out this don't forget to change the address of contract A which I used in contract B. We will call functions in contract B using a high-level call in remix then contract B calls functions in contract A using the low-level `call` function.

`Call` takes a `bytes` parameter as input. When we make a low-level call to a contract how it can understand which function to call? We need to pass the function selector as an argument to call to invoke any function in the contract.

Function selector is 4-byte data that is used to identify functions uniquely in the contract. The function selector is the hash of the function name and corresponding arguments and its value.

Solidity has a built-in function `abi.encodeWithSignature()` that takes two arguments: the name of the function to call and any required arguments. This will return the function selector of the function that passed into `abi.encodeWithSignature()`.

When we call `call_increment_Favourite_Number1()` in contract B, it will make a low-level call to contract A to invoke `increment_Favourite_Number1()` and `abi.encodeWithSignature()` will return the function selector of `increment_Favourite_Number1()` and this will increment the `Favourite_Number1` by 1.

When we call `call_set_Favourite_Number2()` in contract B, it will make a low-level call to contract A to invoke ` set_Favourite_Number2()`. ` set_Favourite_Number2()` takes an input uint256 as an argument. So in `abi.encodeWithSelector()` we need to pass the argument of ` set_Favourite_Number2()` as the second argument to `abi.encodeWithSelector()`. The set_Favourite_Number2() will set the value of Favourite_Number2 to 10 since we passed 10 to `abi.encodeWithSelector()`.

When we call `call_set_Favourite_Number3()` in contract B, it will make a low-level call to contract A to invoke `set_Favourite_Number3()`. The set_Favourite_Number3() function has a required statement to be satisfied. In order to make a successful call to `set_Favourite_Number3()` we need to send ether more than 0.0001. `set_Favourite_Number3()` takes an input string as an argument. So in `abi.encodeWithSelector()` we need to pass the argument of `set_Favourite_Number3()` as the second argument to `abi.encodeWithSelector()`. Since we are sending ether we need to mention the value of ether we are sending in remix. The set_Favourite_Number3() will set Favourite_Number3 to 11 since we passed 10 to `abi.encodeWithSelector()`.

**2. Static Call:** Static call is the same as a call but using a static call we can't make any state changes in the contract. That means when we use staticcall() we cannot change state variables. If we try to do it will revert. staticcall() is used to call functions that return something without changing the state variables of the contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    uint256 public favouriteNumber = 10;

    function view_Favourite_Number() public view returns (uint256) {
        return favouriteNumber;
    }

    function get_Number_Hash(uint256 _num) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_num));
    }
}

contract B {
    A public contract_A;

    constructor(address _contractA) {
    contract_A = A(_contractA);
    }

    function call_view_Favourite_Number() public returns (uint256) {
        (bool success, bytes memory data) = address(contract_A).staticcall(abi.encodeWithSignature("view_Favourite_Number()"));
        require(success, "Call Failed");
        uint256 returnData = abi.decode(data, (uint256));
        return returnData;
    }

    function call_get_Number_Hash(uint256 _num) public returns (bytes32) {
        (bool success, bytes memory data) = address(contract_A).staticcall(abi.encodeWithSignature("get_Number_Hash(uint256)", _num));
        require(success, "Call Failed");
        bytes32 returnData = abi.decode(data, (bytes32));
        return returnData;
    }
}
//Address of A:0xeC2eBD42450940039981e5aAE28a67503bEE4927
//Address of B:0xDab6ba996cd006fc006dF3113893B0D95C4cB44c
```

Here we need to first deploy contract A and then deploy contract B. We will call functions in contract B using a high-level call then contract B calls functions in contract A using a low-level staticcall function.

When we call call_view_Favourite_Number() in contract B, it will make a low-level static call to contract A to invoke view_Favourite_Number(), and `abi.encodeWithSignature()` will return the function selector, and the function view_Favourite_Number() will return 10 since favouriteNumber was set to 10.

When we call call_get_Number_Hash() in contract B, it will make a low-level static call to contract A to invoke `get_Number_Hash()`. `get_Number_Hash()` takes an input uint256 as an argument. So in `abi.encodeWithSelector()` we need to pass the argument of `get_Number_Hash()` as the second argument to `abi.encodeWithSelector()`. The get_Number_Hash() will return a hash of the number passed.

In both of the calls call_view_Favourite_Number() and get_Number_Hash() we are not making any changes to state variables. So Static calls will work successfully. Make sure that you try these sample codes in [remix](https://remix.ethereum.org/) ide to understand static calls in a better way. Also, try changing the state variable owner it will be clearer for you.

**3. Delegate Call:** A `delegatecall` is similar to a normal call, but with a key difference: it allows a contract to execute code from another contract while preserving the context (i.e., `msg.sender` and `msg.value`). This means that the state variables of the calling contract can be modified by the logic in the called contract. Essentially, the logic execution happens in the called contract, but the state changes occur in the calling contract.

Assume there are two contracts, contract A and contract B. Suppose contract A makes a delegate call to contract B to invoke a function. The EVM executes the logic of the function in contract B, but if the function makes any changes to state variables, those changes will be made in contract A. If you don't understand don't worry once you see the example it will be clear. The below is an example.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A{
    uint256 public favourite_Number;

    function increment_favourite_Number()public returns(address){
        favourite_Number++;
        return msg.sender;
    }

}

contract B{
    uint256 public favourite_Number;
    A contract_A;
    constructor(address _addr){
        contract_A =A(_addr);
    }
    function delegatecall_increment_favourite_Number() public returns(address) {
        (bool success, bytes memory data) = address(contract_A).delegatecall(abi.encodeWithSignature("increment_favourite_Number()"));
        require(success, "Delegatecall Failed");
        address return_data = abi.decode(data, (address));
        return return_data;
    }

    function view_favourite_Number()public view returns (uint256) {
        return favourite_Number;
    }
}

```

Here we need to first deploy contract A and then deploy contract B. We will call functions in contract B using a high-level call in remix then contract B calls functions in contract A using the low-level level delegatecall function.

When we call `delegatecall_increment_favourite_Number()` in contract B, it will make a low-level delegate call to contract A to invoke `increment_favourite_Number()`. This function will increment the favourite_Number by 1 and returns `msg.sender`.

As I told earlier `favourite_Number` wont be changed in contract A it will be changed in contract B. Because only the logic part will happen in contract A but if any state changes are there it will happen in contract B. The function `increment_favourite_Number() `in contract A is returning `msg.sender`. In general, it should return the address of contract B. But as it is a delegate call it will return the `msg.sender` of contract B's function.

If it sounds confusing open [remix](https://remix.ethereum.org/) and try it out. Now let's get back to challenge contracts.

First, I will explain the delegate contract.

The contract has a single state variable owner which is initialized to the deployer of the contract in the constructor.

```solidity
function pwn() public {
    owner = msg.sender;
}
```

The function `pwn()` is a public function and it sets the replaces the old owner with the msg.sender

Now I will explain the delegation contract.

The delegation has two state variables: `owner` and `delegate` . The owner is the one who deployed the Delegation contract and delegate is the instance of `Delegate` contract. These two variables are initialized in the constructor.

```solidity
fallback() external {
    (bool result,) = address(delegate).delegatecall(msg.data);
    if (result) {
    this;
    }
}
```

The contract has a `fallback()` function which will be executed when someone sends data to a contract that doesn't match any function selector. The fallback function will make a `delegatecall` to `Delegate` contract with msg.data which is the data sent to the `fallback()` function.

### Exploit

Now it's time to open the console. Open the **Delegation** challenge and press `ctrl`+`shift`+`j` to open the console.

Enter the following

```javascript
> contract.abi
```

This will return all the functions of the contract that was given to us. If we see there are two contracts they will give only one contract instance.

<p align="center">
  <img src="img/img1.png" />
</p>

By looking into abi we can conclude that they have given the instance of a `Delegation` contract. In the Delegation contract if we look into the fallback function it is making a delegate call to the `Delegate` contract. If we see the `Delegate` contract we can find a `pwn()` function which changes the owner to msg.sender. If the `Delegation` contract makes a `delegatecall` to `pwn()` in the `Delegate` contract the owner will be changed in the `Delegation` contract.

But if we look into the `Delegation` contract we can find that the `fallback()` function is making a `delegatecall` to the `Delegate` contract. So somehow we need to call the `fallback()` function with the function selector of `pwn()`.

As I told you earlier `fallback()` will be triggered when we make a call to a contract with an invalid function selector. Our task is to make a call to the `Delegation` contract with the function selector as `pwn()`. As `pwn()` is not in Delegation it will be an invalid function selector in `Delegation` and this will trigger the `fallback()` function and once it is triggered it will make a delegatecall to `Delegate` contract with `msg.data` as function selector of `pwn()`.

Enter the following

```javascript
> const functionSelector = web3.utils.keccak256("pwn()").slice(0, 10);
> await contract.sendTransaction({data: functionSelector})
```

That's it! Once the transaction is completed, you can submit the instance of this challenge.

### Key Takeaways

- **Delegate Call**: `delegatecall` allows a contract to execute code from another contract while preserving the context (i.e., `msg.sender` and `msg.value`). This means that the state variables of the calling contract can be modified by the logic in the called contract. Essentially, the logic execution happens in the called contract, but the state changes occur in the calling contract.

- **Note:** msg.sender and msg.value won't be changed.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
