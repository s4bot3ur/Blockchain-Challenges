# Writeup for Fallout

- Hello h4ck3r welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand solidity well.For every challenge they will deploy the contract and give us the instance of that contract and we need to interact with the contract and exploit. Dont worry If you are completely new to solidity and you never deployed smart contract, you can learn deploying the a contract using remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### challenge

- In this level the challenge is to become owner of the contract.

### Contract Explaination

- Click [here](./src/contracts/Fallout.sol) to view the contract.

- If you feel like you understood the contract you can move to the [exploit](#exploit) part. If you are a begineer please go through contract Explaination also. It will help you to understand the solidity better.

- In this contract, they are using the SafeMath library to prevent overflow and underflow issues

- There are two state variables in contract `allocations` which is mapping of address to uint, and `owner` ,which represents the owner of the contract.

- We can see a comment indicating the presence of a `constructor`. In Solidity, if a function has the same name as the contract, it serves as the constructor. These types of constructors are called as legacy constructor. However, this behavior is only applicable in Solidity versions prior to 0.7.0.

- Then we can see a `modifier` named `onlyOwner`.

```solidity
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }
```

- **Modifiers** are reusable code blocks that can be run before and/or after a function call. In a modifier, everything written before the underscore and semicolon (\_;) is executed before the function call, and everything after the underscore and semicolon is executed after the function call. **Modifiers** are used to check if certain conditions are met before or after calling the function. If the conditions in the modifier are not satisfied, the function call will revert or fail.

- Then we can see a function named allocate().

```solidity
    function allocate() public payable {
        allocations[msg.sender] = allocations[msg.sender].add(msg.value);
    }
```

- The `allocate()` function is a public and payable function, which means it can be called from outside the contract and accepts Ether as payment. When this function is called, it increases the allocation of the caller `(msg.sender)` by adding the value of the sent Ether `(msg.value)` to their current allocation.

```solidity
    function sendAllocation(address payable allocator) public {
        require(allocations[allocator] > 0);
        allocator.transfer(allocations[allocator]);
    }
```

- The `sendAllocation()` function is a public function, which means it can be called from outside the contract. This function takes an address payable parameter allocator and transfers the allocation of the specified allocator to their wallet. However, before making the `transfer`, it checks if the allocation of the allocator is greater than 0 using the require statement. If the allocation is not greater than 0, the function will revert.

```solidity
    function collectAllocations() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }
```

- The `collectAllocations()` function is a public function that allows the owner of the contract to collect all the Ether allocated to the contract. This function uses the onlyOwner modifier, which restricts access to only the owner of the contract. When called, it transfers the entire balance of the contract to the owner's wallet, effectively collecting all the allocations.

```solidity
    function allocatorBalance(address allocator) public view returns (uint256) {
        return allocations[allocator];
    }
```

- The `allocatorBalance()` function is a public view function that takes an address parameter allocator and returns the allocation balance of the specified allocator.

### Exploit

- probably you will know what is a legacy constructor if you read the contract explaination part. If you did not read go and read the constructor part.

- The challenge is to become owner of the contract. The only place the owner is changed is at the constructor. It is supposed to be a constructor.

- If you clearly see the function `Fal1out()` which is supposed to be a consturctor it's name is different from contract name. Instead of **l** it is having **1**. So as the name of function different from contract name it doesn't work as a constructor.

- As it Fal1out() is a normal function we can directly call it and become the owner of the contract.

- Now it's time to open the console. Open **Fallout** challenge and enter `ctrl`+`shift`+`j` to open the console.

```javascript
> await contract.Fal1out()
```

<p align="center">
  <img src="img/img1.png" />
</p>

- Once you call `Fal1out()` function you can submit the challenge.

<p style="text-align:center;">***Hope you enjoyed this write-up. Keep on hacking and learning!***</p>
