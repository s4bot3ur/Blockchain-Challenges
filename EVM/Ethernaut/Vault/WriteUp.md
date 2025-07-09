# Writeup for Vault

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. For each challenge, a contract will be deployed and its instance will be provided. Your task is to interact with the contract and exploit its vulnerabilities. Don't worry if you are new to Solidity and have never deployed a smart contract before. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge

- The goal of this level is to unlock the vault and pass the challenge!

### Contract Explanation

Click [here](./src/contracts/Vault.sol) to view the contract.

If you feel like you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.

The contract has two state variables: `locked` and `password`. `locked` is a **boolean** variable and it is initialized to true in the constructor. `password` is a **bytes32** variable and it is initialized to a **bytes32** value in the constructor.

```solidity
constructor(bytes32 _password) {
    locked = true;
    password = _password;
}
```

The constructor initializes the `locked` variable to true and the `password` variable to the value of `_password`, which is an argument to the constructor.

```solidity
function unlock(bytes32 _password) public {
    if (password == _password) {
        locked = false;
    }
}
```

The function `unlock()` is a public function that takes a **bytes32** `_password` as an argument. If the value of `_password` matches the value of `password`, the function sets the `locked` variable to false.

### Exploit

By looking into the code, we can see that we can unlock the vault by calling the `unlock()` function with the password as an argument.

We can see that the `password` is a `private` variable, which means it can only be accessed by functions within the contract. It is not visible to outside contracts. So we can't know the `password` value by interacting with the contract. If we check the ABI, we cannot find the `password` because its visibility is restricted to only that contract. If it were public, anyone outside the contract could interact with the contract and know the `password`.

Now it's time to open the console. Open the **Vault** challenge and press `ctrl`+`shift`+`j` to open the console.

```javascript
> contract.abi
```

<p align="center">
  <img src="img/img1.png" />
</p>

In the ABI, we can't find the password. So now how can we get the password?

Now for a moment, let's come out of this challenge and think about what blockchain is and what is so special about blockchain.

You are right!! It's immutability and transparency. The entire data of a blockchain is public and anyone will be able to see any transaction in the blockchain.

Now let's discuss the different types of variables in Solidity. There are three types of variables in Solidity.

1. **State Variables:** Variables whose values are permanently stored in a contract storage.
2. **Local Variables:** Variables whose values are present till the function is executing.
3. **Global Variables:** Special variables that exist in the global namespace used to get information about the blockchain.

Check the below contract to understand the different types of variables.

```solidity
contract Variables{
    uint256 State_number; // State Variable which means it is stored permanently in blockchain

    function set_State_number(uint256 _num)public{
        uint256 _temp=_num; // Local variable which means the _temp value will be stored in memory and
                            // Once function execution completes the storage of _temp will be freed.
        State_number=_temp;
    }

    function get_blockhash()public returns(bytes32){
        return blockhash(block.number-1);
        /*blockhash is a global variable. for simpler understanding assume global variables as a function which
        * is not defined by you but you can use it anywhere in the contract.
        */
    }
}
```

Now let's understand where these variables are stored. Local variables are stored in memory, which is a temporary storage. Once the function execution completes, the memory storage given to a particular local variable will be freed.

State variables are stored in the contract's permanent storage, unlike local variables stored in memory. To be more clear, let's assume the contract has two kinds of storage: permanent storage and temporary storage. State variables are stored in permanent storage and local variables are stored in permanent storage.

Now let's dive into how state variables storage works. Assume you have a book containing 200 pages and you have written some important data on the 100th page. The next day you want to see the data, how are you going to refer to that data? Will you go from page 1 to page 100 and check for data, or will you directly open the 100th page since you know the data is stored on the 100th page? Obviously, you will directly open the 100th page and check for data.

The same way, just like pages in a book, we have storage slots in EVM. A page in a book contains a certain number of lines to be filled, and in storage slots, we can store a maximum of 32 bytes. In a page, you may or may not fill all the lines, same way here the storage slot may or may not contain a full 32 bytes of data. Suppose you have a large amount of data to be stored that cannot be filled in one single page, then how are you going to write? You will write whatever data fills this page and write the remaining data in another page. Same way, we store large amounts of data in different slots, but it won't be the same as how we write in a book, it will be different. I will be explaining it in the coming challenges.

So, as far as we understood, EVM stores state variables in storage slots. So, if there is some data stored in one of the slots, how can you get that particular data? We can get that data by using the key. The key is basically the slot number. Just like an array has indexes from 0, storage slots also start from 0. The first 32 bytes of data will be stored in slot 0, and the next 32 bytes will be stored in slot 2, etc. Check the following example.

```solidity
contract Storage_slots{
    bool boolean=true; // 1 byte
    uint256 number=256;  //32 bytes
    uint128 number1=100; //16 bytes
    uint128 number2=101; //16 bytes

    //1 byte=8bits
    //uint256=256 bits =32 bytes

    //slot 0: boolean
    //slot 1: number
    //slot 2: number1,number2
}
```

Now, if we check the state variables of the contract, the first variable is `locked`, which is of type **bool**, and the second state variable is `password`, which is of type **bytes32**. So, `locked` will be stored in the 0th slot, and `password` will be stored in the 1st slot.

The web3 library has a function named `getStorageAt()` that takes the contract address and slot number as arguments and returns the value at the slot.

Our challenge is to unlock the vault. If we know the password, we can unlock the vault. Enter the following:

```javascript
> await web3.eth.getStorageAt(contract.address,1)
```

Now, once we get the password, we need to call the `unlock()` function by passing the password as an argument to `unlock()`.

```javascript
> await contract.unlock("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")
```

We can verify whether the vault is unlocked or not by calling `locked()`.

```javascript
> await contract.locked()
```

<p align="center">
  <img src="img/img2.png" />
</p>

That's it! The challenge is solved. Now we just need to submit the challenge.

### Key Takeaways

We should not store any important data in smart contracts. Even though the state variables view is private, it can be accessed by anyone.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
