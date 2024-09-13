# Writeup for Fallback

- Hello h4ck3r welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand solidity well.For every challenge they will deploy the contract and give us the instance of that contract and we need to interact with the contract and exploit. Dont worry If you are completely new to solidity and you never deployed smart contract, you can learn deploying the a contract using remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge

- In this level our task is claim ownership of this contract and make the balance of the contract to zero.
- Click [here](./src/contracts/Fallback.sol) to view the source code

### Solution

- First i will explain every function in the contract.

- The contract has two state variables one is mapping named contributions which stores individual person to their contributions and a owner state variable which is initialized during the deployment of contract.

- In the constructor it is setting up the owner to `msg.sender` and it is setting the contributions of `msg.sender` to `1000 ether`.

```solidity
    constructor() {
        owner = msg.sender;
        contributions[msg.sender] = 1000 * (1 ether);
    }
```

- **Note:** `msg.sender` is the address of the user or contract that is interacting with the contract. This can be thought of as the "sender" of the message or transaction.
- **Note:** `msg.value` is the amount of Ether that is being sent to the contract as part of a transaction. This can be thought of as the "value" being transferred to the contract.

```solidity
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }
```

- **Modifiers** are code that can be run before and / or a function call. Everything written before underscore and semicolon is executed before the function call and everything after underscore and semicolon will be executed after the function call. **Modifiers** are used to check some conditions are met or not before or after calling the function. If the conditions in modifier are not satisfied then the function call fails.

```solidity
    function contribute() public payable {
        require(msg.value < 0.001 ether);
        contributions[msg.sender] += msg.value;
        if (contributions[msg.sender] > contributions[owner]) {
            owner = msg.sender;
        }
    }
```

- The function `contribute()` is a public function. Initially it checks for if `msg.value` is less than `0.001 ether` or not. If yes it will continue executing the next statements else it will revert. Then it is updating the contributions of the `msg.sender` with the ether that has sent during the function call. Then it checks if the contributions of `msg.sender` is greater than existing owner or not. If yes then it will make the msg.sender as the new owner.

- We can see that the existing owner was set in constructor during the deployment of contract. The **owner** was set to the address of one who deployed balance with balance of **1000 ether**.

- In order to claim the ownership we need to send more than **1000 ether** during the function call. But, it is not possible due to initial checks.

```solidity
    function getContribution() public view returns (uint256) {
        return contributions[msg.sender];
    }
```

- This function will just return the contributions of the caller of this function. If you are interacting with this function with your wallet, it will return your contributions. Similarly, if someone else calls this function with their wallet, it will return their contributions.

```solidity
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
```

- The function `withdraw()` is a public function. It uses the **modifier** `onlyOwner()` defined above to check whether owner is calling the `withdraw()` or not.

- So inorder to withdraw first we need to become owner of the contract.

```solidity
    receive() external payable {
        require(msg.value > 0 && contributions[msg.sender] > 0);
        owner = msg.sender;
    }
```

- This is the last function in the contract. `receive()` is a inbuilt function in solidity. In short to explain receive will be invoked when you interact with contract without any data or function calls. When you send some ether to contract without calling any function then `receive()` will be invoked.

- We can see `receive()` function is checking for `msg.value` is greater than zero or not and if msg.sender already has some contributions or not. If both the conditions are satisfied then it is making **owner** to `msg.sender`.

- I hope by this time you got an idea what to do. If not dont worry iam here to explain.

- If we make a small contribution worth less than 0.001 ether to the contract by calling contribute() and then send some ETH to the contract without calling any function and without any data, we will become the owner. Once we become the owner, what else do we need to do to just drain the balance of contract?

- Ethernaut is using truffle framework and truffle has a method named `sendTransaction()`. it is a method used to send a transaction to the Ethereum network. It's a part of the `web3.eth` module, which provides an interface to interact with the Ethereum blockchain.

- Now it's time to open the console. Open fallback challenge and enter `ctrl`+`shift`+`j` to open the console.

```javascript
> await contract.contribute.sendTransaction({ from: player, value: 1})
```

- This will call `contribute()` function with `1 wei`. Since 1 wei is less than 0.001 ether (1000000000000000 wei). `Wei` is the smallest denomination of ether. `1 ether` = `10^18 wei`.

```javascript
> await contract.sendTransaction({ from: player, value: 1})
```

- This will call the contract directly without specifying a function. In this case, it will send `1 wei` to the contract. Since no function is specified, this call will invoke the `receive()` function, if it exists. If there is no `receive()` function in the contract we won't be able to call contract without specifying a function.

- Once this transaction is successful we will become the `owner`. Now we need to just drain the balance of contract by calling `withdraw()`.

```javascript
> await contract.withdraw()
```

- this will `withdraw()` Ether from the contract to your address, available only to the successful `owner`.
<p align="center">
  <img src="img/img1.png" />
</p>

- Once you call `withdraw()` the challenge will be completed. Now you can click on submit instance to complete this challenge.

### Key Takeaways

- The **receive** function is a special function in Solidity that is called when a contract receives Ether (ETH) from an external source, such as a user or another contract. This function is used to handle the incoming Ether and perform any necessary actions.

<p style="text-align:center;">***Hope you enjoyed this write-up. Keep on hacking and learning!***</p>
