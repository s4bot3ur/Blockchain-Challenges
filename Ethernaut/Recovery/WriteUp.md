# Writeup for Naught Coin

- Greetings, aspiring hacker! Welcome to the realm of smart contract hacking. By solving the challenges from Ethernaut, you will gain a deeper understanding of Solidity. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

In this challenge, a contract creator has built a simple token factory contract. Creating new tokens is a breeze. After deploying the first token contract, the creator sent 0.001 ether to obtain more tokens. Unfortunately, they have lost the contract address.

To complete this level, your task is to recover (or remove) the 0.001 ether from the lost contract address.

### Contract Explanation

Before diving into the [exploit](#exploit) part, it's essential to understand the contract. If you're new to Solidity, reading the Contract Explanation will provide you with a better grasp of the language.

<details>
<summary>Click to view the source contract and contract explanation</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    //generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {
    string public name;
    mapping(address => uint256) public balances;

    // constructor
    constructor(string memory _name, address _creator, uint256 _initialSupply) {
        name = _name;
        balances[_creator] = _initialSupply;
    }

    // collect ether in return for tokens
    receive() external payable {
        balances[msg.sender] = msg.value * 10;
    }

    // allow transfers of tokens
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    // clean up after ourselves
    function destroy(address payable _to) public {
        selfdestruct(_to);
    }
}
```

This challenge consists of two contracts: `Recovery` and `SimpleToken`. Let's start with the `Recovery` contract. It has a single function:

```
function generateToken(string memory _name, uint256 _initialSupply) public {
    new SimpleToken(_name, msg.sender, _initialSupply);
}
```

This function creates a new instance of the `SimpleToken` contract by taking two arguments: a string `_name` and a uint256 `_initialSupply`.

Now, let's move on to the `SimpleToken` contract.

The `SimpleToken` contract has two state variables: `name` (a string) and `balances` (a mapping of addresses to uint256).

The constructor of `SimpleToken` takes three arguments: `_name` (a string), `_creator` (an address), and `_initialSupply` (a uint256). It sets the `name` state variable to the provided `_name` and assigns the `_initialSupply` to the `balances` mapping for the `_creator` address.

```solidity
receive() external payable {
    balances[msg.sender] = msg.value * 10;
}
```

The `receive()` function is a built-in function in Solidity. It is invoked when someone interacts with the contract without calling any specific function or with data that doesn't match any function selector. In this case, when someone sends ether to the contract without calling any function, the `receive()` function is triggered. It sets the balance of the `msg.sender` (the caller) to the value of the sent ether multiplied by 10.

```solidity
function transfer(address _to, uint256 _amount) public {
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
}
```

The `transfer()` function allows the transfer of tokens. It takes two arguments: `_to` (the address to transfer the tokens to) and `_amount` (the amount of tokens to transfer). Before executing the transfer, it checks if the caller has a sufficient balance. If the balance is enough, it deducts the `_amount` from the caller's balance and adds it to the `_to` address.

```solidity
function destroy(address payable _to) public {
    selfdestruct(_to);
}
```

The `destroy()` function takes an address `_to` as an argument and calls the `selfdestruct()` function with `_to` as the argument. To understand how `selfdestruct()` works, refer to the [concepts](#) section.

</details>

### Key Concepts To Learn

The main concept to focus on in this challenge is the usage of `selfdestruct()`. Additionally, you can explore RLP encoding if you're interested.

`selfdestruct()` is a built-in function in Solidity. When called, it is supposed to delete the contract bytecode from the Ethereum network and send the contract's balance to the specified address.

However, due to the implementation of EIP-6780 in the Dencun upgrade on March 13, 2024, the behavior of `selfdestruct` has changed. It now only sends the contract's ether balance to the specified address but does not delete the contract bytecode from the Ethereum network.

Deleting the contract bytecode is still possible after the update, but only if `selfdestruct` is called in the same transaction in which the contract is created.

The address of an Ethereum contract is determined by the creator's address (sender) and the number of transactions the creator has sent (nonce). The **sender** and **nonce** are `RLP-encoded` and then hashed with `Keccak-256`.

```python
import rlp #python -m pip install rlp
from sha3 import keccak_256

def get_Contract_Address(sender,nonce):
    contract_address = keccak_256(rlp.encode([sender, nonce])).hexdigest()[-40:]
    return contract_address


sender_address=input("Enter the sender (contract creator) address :")
nonce=int(input("Enter the Nonce :"))
sender=sender_address[2:]
sender=bytes.fromhex(sender)
print(get_Contract_Address(sender,nonce))

```

Enter the following in the terminal to download `rlp` module.

```shell
$ python -m pip install rlp
```

Enter the address of the Externally Owned Account and enter the nonce of the externally owned account. Whenever you deploy a contract using your wallet or interact with a function that makes state changes for every transaction, the nonce will be increased. You can find your nonce in your wallet or Block Explorer.

### Exploit

Enter `ctrl + shift + j` and open the console, then enter the following:

```javascript
> contract.abi
```

When we enter this, we can find that our instance has only one function named `generateToken()`. By this, we can say that they have given us the instance of the `Recovery` contract.

Now our task is to find the address of the `SimpleToken` contract and call the `destroy()` function. We can find the address of SimpleToken in two ways. One way is using the block explorer, and another way is calculating the address of SimpleToken with the help of the `Recovery` contract address and the nonce of the `Recovery` contract address. First, I will explain how you can find the address using the block explorer.

Click [here](https://sepolia.etherscan.io) to open the block explorer. When you click the link, you can find it as shown in the image below:

<p align="center">
  <img src="img/img1.png" />
</p>

In the search bar, search for the address of the `Recovery` (instance) contract. When you search, you will find it as shown below:

<p align="center">
  <img src="img/img2.png" />
</p>

You can't find any transactions because no one has invoked any function in this contract. Now click on internal transactions. Once you click, you will find it as shown below:

<p align="center">
  <img src="img/img3.png" />
</p>

Now you can find two contract creations. The one at the bottom is the contract creation of this contract, and the one at the top is this contract creating another contract. This (`Recovery`) contract created the `SimpleToken` contract. So the top one is the address of the `SimpleToken` contract. Click on the contract creation of the top one. Once you click, you will find it as shown below:

<p align="center">
  <img src="img/img4.png" />
</p>

This is the address of the `SimpleToken` contract. `SimpleToken` contract has a balance of 0.01 ether. Since we got the address of the `SimpleToken`, we can call the `destroy()` function now.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Itoken{
    function destroy(address paayble) external;
}

contract ExploitSimpleToken{

    Itoken simpleToken;
    constructor(address _addr){
        simpleToken=Itoken(_addr);
    }

    function Exploit()public{
        simpleToken.destroy(msg.sender);
    }

}

```

Deploy this contract, and during deployment, pass the address of `SimpleToken` to the constructor of the `ExploitSimpleToken` contract. Then call the `Exploit()` function. Once the transaction is complete, the challenge will be solved.

### Key Takeaways

The Ethereum contract address is generated in a deterministic manner using the creator's address (sender) and the number of transactions they have sent (nonce). To compute the address, the sender and nonce are encoded using RLP (Recursive Length Prefix) and then hashed with the Keccak-256 algorithm.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
