# Writeup for Delegation

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity well. For each challenge, they will deploy the contract and provide us with the instance of that contract. Our task is to interact with the contract and exploit it. Don't worry if you are completely new to Solidity and have never deployed a smart contract. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge

- The goal of this level is to make the balance of the contract greater than zero.

### Contract Explanation

Click [here](./src/contracts/Force.sol) to view the contract.

If you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.

Before starting with contracts, I would like to explain an inbuilt function named `selfdestruct()` in Solidity.

**selfdestruct:** `selfdestruct()` is an inbuilt function in Solidity that takes an address parameter as input. When `selfdestruct()` is executed, it will delete the contract code from Ethereum. If that contract has any ether, it will be sent to the address passed to `selfdestruct()`.

The behavior of `selfdestruct` was changed with the implementation of EIP-6780 in the Dencun upgrade that went live on March 13, 2024. Now it will only send the ether from that contract to the address passed into `selfdestruct()`. After this change, the contract code will be deleted only if the contract creation and `selfdestruct()` happen in the same transaction.

If we see the contract, we don't have any functions in the contract. It is just an empty contract. We can send ether to a contract only if it has some `payable` functions or a `receive()` function. As there are no functions, we cannot send ether directly to the contract.

### Exploit

As there is no function in the contract, we need to find another method to send ether to the contract.

The only way we can send ether to this contract is by creating an exploit contract with a function that executes `selfdestruct()` and passing the address of the instance contract.

```solidity
function Exploit(address _force) public {
    selfdestruct(payable(address(_force)));
}
```

We need to send some ether to the exploit contract so that when we call the `Exploit()` function, it will send the ether it has to the force contract, increasing the force contract's balance. We can send ether to the exploit contract during deployment itself.

When we use `selfdestruct()`, it will send ether directly to the address passed as an argument, regardless of whether there is a `receive()` function or any `payable` function existing in the address passed to `selfdestruct`.

Click [here](./Exploit/Exploit.sol) to view the exploit contract.

Once you call the Exploit() function the challenge will be solved.

### Key Takeaways

- **Ether Transfer:** selfdestruct() can send ether to any address, regardless of whether the target address has a receive() or payable function.

- **Contract Code Deletion:** Post-EIP-6780, the contract code is deleted only if selfdestruct() is called in the same transaction as the contract creation.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
