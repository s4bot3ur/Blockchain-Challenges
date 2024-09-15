# Writeup for Telephone

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity well. For each challenge, they will deploy the contract and provide us with the instance of that contract. Our task is to interact with the contract and exploit it. Don't worry if you are completely new to Solidity and have never deployed a smart contract before. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge

- Claim ownership of the contract below to complete this level.

### Contract Explanation

- Click [here](Ethernaut/Telephone/src/contracts/Telephone.sol) to view the contract.

- If you feel like you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.

- The contract has a single state variable called `owner`, which is initialized during the deployment of the contract.

```solidity
    constructor() {
        owner = msg.sender;
    }
```

- In the above code snippet, the constructor initializes the `owner` variable to `msg.sender`. In the context of the constructor, `msg.sender` refers to the address of the person deploying the contract.

```solidity
    function changeOwner(address _owner) public {
        if (tx.origin != msg.sender) {
            owner = _owner;
        }
    }
```

- The function `changeOwner()` is a public function that takes an address parameter `_owner`. `_owner` is the address of the new proposed owner.

- The function checks if `tx.origin` and `msg.sender` are equal or not. If they are not equal, then the proposed `_owner` address will become the new owner of the contract.

- Now you might be wondering what `tx.origin` is. Don't worry, I'm here to explain.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hi{
    address sender;
    Hello hello=Hello(0xd9145CCE52D386f254917e481eB44e9943F39138);

    function bye()public returns(string memory){
        sender=msg.sender;
        return hello.Goodbye();
    }

    function view_sender()public view returns(address){
        return sender;
    }

}

contract Hello{
    address origin;
    function Goodbye()public pure returns (string memory){
        origin=tx.origin;
        return msg.sender;
    }

    function view_origin()public returns(address){
        return origin;
    }
}


//Address of Hi: 0xf8e81D47203A594245E36C48e151709F0C19fBe8
//Address of Hello: 0xd9145CCE52D386f254917e481eB44e9943F39138

```

- Let's assume there are two contracts named **Hi** and **Hello**. The contract **Hi** has a function called `bye()` and **Hello** has a function called `Goodbye()`.

- When we deploy these two contracts and call the `bye()` function in contract **Hi**, the following will happen:

  - First, the `sender` variable will be updated to `msg.sender`. Here, `msg.sender` will be our address since we are calling the `bye()` function.

  - Then, it will call the `Goodbye()` function in the **Hello** contract and return the value returned by `Goodbye()`.

  - Next, `Goodbye()` will update the `origin` variable with `tx.origin` and then return `msg.sender`. Since the **Hi** contract is calling `Goodbye()` in the **Hello** contract, the `msg.sender` will be the address of the **Hi** contract.

  - `tx.origin` refers to the address that initiated the transaction. In this case, we called the `bye()` function initially. So, the `origin` variable in the **Hello** contract is set to our address, and it returns the address of the **Hi** contract.

  - When you are trying out call `view_origin()` and `view_origin()` to verify.

- If you are confused, you can open [Remix](https://remix.ethereum.org/) and try the above example. It will be much clearer.

- If you are unfamiliar with Remix, you can refer to this video tutorial: [Remix Tutorial](https://www.youtube.com/watch?v=WmeWbo7wzGI).

### Exploit

- The only condition we need to satisfy in the `changeOwner()` function is to make `tx.origin` not equal to `msg.sender`.

- Similar to the previous challenge, if we write an exploit contract and call the `changeOwner()` function from the exploit contract, then `msg.sender` will be the address of the exploit contract and `tx.origin` will be our wallet address.

- Click [here](/Exploit/ExploitCoinFlip.sol) to view the exploit contract. In Remix, during deployment, we need to provide the address of the `Telephone` contract as an argument to the constructor of the exploit contract.

- Deploy the exploit contract and call the `Exploit()` function in the **ExploitTelephone** contract.

- Once the call is done, submit the challenge instance.

### Key Takeaways

- The difference between `msg.sender` and `tx.origin` is crucial in understanding Ethereum smart contract security:
  - `msg.sender`: This is the address of the immediate account (either a contract or an external account) that called the current function.
  - `tx.origin`: This is the address of the original externally owned account that initiated the transaction, regardless of how many contracts were called in between.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
