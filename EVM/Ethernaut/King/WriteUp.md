# Writeup for King

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. For each challenge, a contract will be deployed, and an instance will be provided. Your task is to interact with the contract and exploit its vulnerabilities. Don't worry if you are new to Solidity and have never deployed a smart contract before. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge

- The contract below represents a very simple game: whoever sends an amount of ether that is larger than the current prize becomes the new king. On such an event, the overthrown king gets paid the new prize, making a bit of ether in the process! It's as ponzi as it gets xD

- Your goal is to break this game.

- When you submit the instance back to the level, the level is going to reclaim kingship. You will beat the level if you can avoid such a self-proclamation.

### Contract Explanation

Click [here](./src/contracts/King.sol) to view the contract.

If you feel like you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.

The contract has three state variables: `king`, `prize`, and `owner`. `king` represents the address of the current king, `prize` represents the ether sent by a person to become the king, and `owner` represents the owner of this contract.

```solidity
constructor() payable {
    owner = msg.sender;
    king = msg.sender;
    prize = msg.value;
    }
```

The constructor initializes `owner` and `king` to `msg.sender`, and `prize` to `msg.value`. Initially, the deployer of the contract will be the `king` and `owner` of this contract.

```solidity
receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
    }
```

The `receive()` function is a special function in Solidity. It will be triggered when you send some ether to the contract without calling any function.

In the function logic, it checks if the `msg.value` (ether) sent during the call is greater than or equal to the prize of the current king, or if the `msg.sender` (caller) is the owner of the contract. If either of these conditions is true, the execution continues, otherwise, it reverts.

Then, it transfers the ether deposited by the old king to the old king because once the `require()` statement is passed, the king will be changed. So, when the king changes, the old king needs to receive the amount of ether deposited by them to become king. Once the transfer is done, the king is set to `msg.sender` (caller) and the prize is set to `msg.value` (the ether deposited by the new king).

The function `_king()` is a public `view` function that returns the address of the current `king`.

### Exploit

The contract works based on a simple logic: whoever sends more ether than the current king becomes the new king, and the contract sends the amount of ether deposited by the old king to them.

If we become the king using an `Externally Owned Account` (EOA), everything works as normal. However, if we make a smart contract become the king, the King contract will work as expected only if the contract is able to receive the ether when a new person becomes the king.

We know that a contract can receive ether in two ways: one way is through defining a normal payable function, and the other way is by having a `receive()` function. See the example below to understand.

```solidity

contract Receive_Ether {

 function Receive_ether() public payable {
    // This function allows the contract to receive Ether when it is called.
    // The 'payable' keyword is necessary for the function to accept Ether.
    // If the function is not marked as 'payable', any attempt to send Ether will cause the transaction to revert.

    // The logic of this function can be anything. The contract will receive ether irrespective of the logic.
    }

    receive() external payable {
    // This receive() function allows the contract to receive Ether when it is sent directly to the contract address.
    // This function is called when no other function matches the call data.
    }
}

```

Now, if we create an exploit contract without a `receive()` function and make the contract the king, the challenge will be solved.

Click [here](./Exploit/ExploitKing.sol) to view the exploit contract.

Now, we just need to deploy the contract and call the `Exploit()` function with some ether.

```solidity
function Exploit() public payable {
    (bool success,) = address(king).call{value: msg.value}("");
    require(success, "Exploit Failed");
}
```

Our task is to know the amount of ether deposited by the current king and send more ether than the current king.

Now, it's time to open the console. Open the **King** challenge and press `ctrl`+`shift`+`j` to open the console.

```javascript
> (await contract.prize()).toString()
```

This will return the ether deposited by the current king, which is `1000000000000000` wei. We need to send more than `1000000000000000` wei to become the king. We can send `1000000000000001` wei to become the king.

Open Remix and deploy the exploit contract. When calling the `Exploit()` function, we need to send `1000000000000001` wei.

<p align="center">
  <img src="img/img1.png" />
</p>

We can find the `VALUE` section in the Remix deployment options. We need to enter `1000000000000001` in the `VALUE` field and call the `Exploit()` function.

That's it! Once we call the `Exploit()` function, the challenge will be solved.

### Key Takeaways

When writing a contract, if the logic depends on sending Ether We need to ensure that, it is sent to an Externally Owned Account (EOA).

In this challenge, we can fix this exploit by checking if `tx.origin` is `msg.sender `.

```solidity
    receive() external payable {
    require(tx.origin==msg.sender);
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
 }
```

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
