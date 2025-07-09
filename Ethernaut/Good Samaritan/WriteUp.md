# Writeup for DoubleEntryPoint

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

This instance represents a Good Samaritan that is wealthy and ready to donate some coins to anyone requesting it.

Would you be able to drain all the balance from his Wallet?

Things that might help:

- Solidity Custom Errors

### Key Concepts To Learn

In order to solve this challenge you need to learn how errors works in solidity. I will be explaining two types of errors in solidity.

While writing contracts we will write some checks for function calls. If the checks are not satisfied we will revert. But reverting an be done in two ways. Check the below examples.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FortaA{
    error NotEnoughBalance();

    function hello()external pure {
        revert("NotEnoughBalance()");
    }
}
```

When we revert in this way during the revert the function will return the "NotEnoughBalance()" as string in hex format. Check the below example observe that.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FortaA{

    function hello()external pure {
        revert("NotEnoughBalance()");
    }
}


contract Forta {
    error NotEnoughBalance();
    bytes public mainerr;
    FortaA forta=FortaA(//__FortaA_ADDRESS);


    function notify() external {
        try forta.hello() {
        } catch (bytes memory arr) {
            mainerr=(arr);
        }
    }

}

```

Deploy the FortaA contract first and then Deploy Forta contract. Once you deploy call notify() function in Forta. It will return bunch of bytes data. When you convert that bytes data from hex to string you will get the reverted string. Check the below image.

<p align="center">
  <img src="img/img1.png" />
</p>

Now i will explain custom errors. Check the below example.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FortaA{
    error NotEnoughBalance();

    function hello()external pure {
        revert NotEnoughBalance();
    }
}


contract Forta {
    error NotEnoughBalance();
    bytes public mainerr;
    FortaA forta=FortaA(//__FortaA_ADDRESS);


    function notify() external {
        try forta.hello() {
        } catch (bytes memory arr) {
            mainerr=(arr);
        }
    }

}
```

Deploy the FortaA contract first and then Deploy Forta contract. Once you deploy call notify() function in Forta. It will return function selector of `"NotEnoughBalance()"`.

### Contract Explanation

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

Click [here](./src/contracts/GoodSamaritan.sol) to view the contract source code.

<details>
<summary>Click to view the contract explanation</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "openzeppelin-contracts-08/utils/Address.sol";

contract GoodSamaritan {
    Wallet public wallet;
    Coin public coin;

    constructor() {
        wallet = new Wallet();
        coin = new Coin(address(wallet));

        wallet.setCoin(coin);
    }

    function requestDonation() external returns (bool enoughBalance) {
        // donate 10 coins to requester
        try wallet.donate10(msg.sender) {
            return true;
        } catch (bytes memory err) {
            if (keccak256(abi.encodeWithSignature("NotEnoughBalance()")) == keccak256(err)) {
                // send the coins left
                wallet.transferRemainder(msg.sender);
                return false;
            }
        }
    }
}


```

First i will explain GoodSamaritan contract.

GoodSamaritan contract has two state variables wallet (address) and coin (address) . wallet is of type Wallet and coin is of type Coin. Wallet and Coin are two contracts.

```solidity

constructor() {
    wallet = new Wallet();
    coin = new Coin(address(wallet));

    wallet.setCoin(coin);
}

```

The constructor creates a `Wallet` contract and `Coin` contract. Then it will call the `setCoin()` function in the `Wallet` contract.

```solidity
function requestDonation() external returns (bool enoughBalance) {
        // donate 10 coins to requester
        try wallet.donate10(msg.sender) {
            return true;
        } catch (bytes memory err) {
            if (keccak256(abi.encodeWithSignature("NotEnoughBalance()")) == keccak256(err)) {
                // send the coins left
                wallet.transferRemainder(msg.sender);
                return false;
            }
        }
    }
```

The function `requestDonation()` is an external function, which means it can only be called by other contracts or EOAs. The function will execute the code in the `try` block and call the `donate10()` function in the `Wallet` contract. If the function call is successful, it will return `true`. If there is any error while calling the `donate10()` function, then the code in the `catch` block will execute instead of reverting. The `catch` block will check if the error is `NotEnoughBalance()` or not. If it is `NotEnoughBalance()`, then it will call the `transferRemainder()` function in the `Wallet` contract and then return `false`.

Now i will explain the Coin contract.

```solidity

interface INotifyable {
    function notify(uint256 amount) external;
}

contract Coin {
    using Address for address;

    mapping(address => uint256) public balances;

    error InsufficientBalance(uint256 current, uint256 required);

    constructor(address wallet_) {
        // one million coins for Good Samaritan initially
        balances[wallet_] = 10 ** 6;
    }

    function transfer(address dest_, uint256 amount_) external {
        uint256 currentBalance = balances[msg.sender];

        // transfer only occurs if balance is enough
        if (amount_ <= currentBalance) {
            balances[msg.sender] -= amount_;
            balances[dest_] += amount_;

            if (dest_.isContract()) {
                // notify contract
                INotifyable(dest_).notify(amount_);
            }
        } else {
            revert InsufficientBalance(currentBalance, amount_);
        }
    }
}

```

The `Coin` contract has a single state variable `balances`. The `balances` is a mapping of address to `uint256`. It basically stores the balance of each address that holds this coin.

The contract is using the `Address` library for address variables, which means all the functions in the library can be used on addresses.

The contract has an error `InsufficientBalance()` which takes two arguments of type `uint256` as inputs.

```
constructor(address wallet_) {
    // one million coins for Good Samaritan initially
    balances[wallet_] = 10 ** 6;
}
```

In the constructor, it takes the address of the `Wallet` contract as input and sets the balance of the Wallet `contract` to 10^6. The `GoodSamaritan` contract passes the address of Wallet contract to the constructor of Coin contract.

```solidity
function transfer(address dest_, uint256 amount_) external {
    uint256 currentBalance = balances[msg.sender];
    // transfer only occurs if balance is enough
    if (amount_ <= currentBalance) {
        balances[msg.sender] -= amount_;
        balances[dest_] += amount_;

        if (dest_.isContract()) {
            // notify contract
            INotifyable(dest_).notify(amount_);
        }
    } else {
        revert InsufficientBalance(currentBalance, amount_);
    }
}

```

The `transfer()` function takes two arguments of type **address** (dest*) and **uint256** (amount*) as input. The function will make some checks, and if all checks pass, it will send the specified amount to the destination address. If the destination address is a contract, it will call the `notify()` function in the destination contract.

Now let's go through `Wallet` contract.

```solidity
contract Wallet {
    // The owner of the wallet instance
    address public owner;

    Coin public coin;

    error OnlyOwner();
    error NotEnoughBalance();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function donate10(address dest_) external onlyOwner {
        // check balance left
        if (coin.balances(address(this)) < 10) {
            revert NotEnoughBalance();
        } else {
            // donate 10 coins
            coin.transfer(dest_, 10);
        }
    }

    function transferRemainder(address dest_) external onlyOwner {
        // transfer balance left
        coin.transfer(dest_, coin.balances(address(this)));
    }

    function setCoin(Coin coin_) external onlyOwner {
        coin = coin_;
    }
}



```

The `Wallet` contract has a state variable of type `Coin` (address).

The contract has two errors defined: `OnlyOwner()` and `NotEnoughBalance()`.

The `onlyOwner()` modifier will check if the `msg.sender` (caller) is the owner or not. If the caller is not the owner, it will revert with the `OnlyOwner()` error.

The `constructor` sets the owner to `msg.sender` (deployer of Wallet contract).

```solidity
function donate10(address dest_) external onlyOwner {
    // check balance left
    if (coin.balances(address(this)) < 10) {
        revert NotEnoughBalance();
    } else {
        // donate 10 coins
        coin.transfer(dest_, 10);
    }
}
```

The `donate10()` function will take an argument of type **address** as input and execute the `onlyOwner` modifier. If the modifier passes, it will check if the `Wallet` contract has enough balance. If the `Wallet` contract balance is less than 10, it will revert with a `NotEnoughBalance()` error. If it has a balance of 10 or more, it will call the `transfer()` function in the `Coin` contract.

```solidity
function transferRemainder(address dest_) external onlyOwner {
    // transfer balance left
    coin.transfer(dest_, coin.balances(address(this)));
}
```

The `transferRemainder()` function will take an argument of type **address** (dest\_) as input and execute the `onlyOwner` modifier. If the modifier passes, it will call the `transfer` function by passing the destination address and the balance of the `Wallet` contract as arguments.

```solidity
function setCoin(Coin coin_) external onlyOwner {
    coin = coin_;
}
```

The `setCoin()` function will take an argument of type `Coin` (address) as input and execute the `onlyOwner` modifier. If the modifier passes, it will set the `coin` to the new `Coin` passed.

</details>

### Exploit

Our goal is to drain the balance of the Wallet contract.

We was given the instance of GoodSamaritan contract. In this contract the only function with which we can interact is requestDonation().

When we call `requestDonation`, it will call the `donate10()` function in the `Wallet` contract. The `donate10()` function will check whether the `Wallet` contract has a balance less than 10 or not. If it has a balance less than 10, it will revert with the `NotEnoughBalance()` error. If it has a balance of 10 or more, it will call the `transfer()` function in the `Coin` contract. The `transfer()` function will transfer 10 coins to the address passed by `donate10()`. If the receiver is a contract, the `transfer()` function will call the `notify()` function in the receiver.

But if the `donate10()` function reverts with the `NotEnoughBalance()` error, then the `requestDonation()` function in `GoodSamaritan` will call the `transferRemainder()` function in the `Wallet` contract. The `transferRemainder()` function will transfer the entire balance of the `Wallet` contract to the address passed by `donate10()`.

According to the contract logic, the `NotEnoughBalance()` error will be thrown only if the balance of the `Wallet` contract is less than 10. So when the balance is less than 10, it transfers the entire balance to the latest person who called the `requestDonation()` function in the `GoodSamaritan` contract. After this call, no one will be able to call `requestDonation()` and get donations.

If we check the constructor of the `Coin` contract, it sets the balance of the `Wallet` to 10^6. So, in order to drain the balance of the `Wallet` contract, we need to call the `requestDonation()` function 10^5 times, which will be a time-consuming task. Therefore, we need a shorter way to get the entire coins.

If we somehow make the `donate10()` function revert with the message `NotEnoughBalance()`, then it will transfer the entire tokens.

Suppose there are three contracts, and a function in one of the contracts calls functions in the other two contracts. If the functions in the other two contracts return the same error upon failure of some conditions, then the calling function won't be able to determine which contract the error originated from. We can take this as advantage and we can exploit the GoodSamaritan contract.

Now when we call the `requestDonation` in the `GoodSamaritan` contract, it will call `donate10()` in the `Wallet` contract. Then `donate10()` will call `transfer()` in the `Coin` contract, and the `transfer()` function will transfer 10 coins to the receiver. If the receiver is a contract, it will call the `notify()` function in the receiver contract, passing the amount of the transfer as an argument to `notify()`.

So in our `Exploit` contract, when the `notify()` function is called, we need to check if the transfer amount is 10 or not. If it is 10, then we need to revert with a `NotEnoughBalance()` error. Then the `transfer()` function will be reverted, and subsequently, the `donate10()` function will be reverted. Both calls will be reverted with data as the function selector of the `NotEnoughBalance()` error. Now the `try` block in `requestDonation()` will fail, and it will execute the `catch` block by passing the same error. Since the error returns the function selector of `NotEnoughBalance()`, the `if` condition will pass, and it will transfer the entire coins to the `requestDonation()` caller.

Below is the Exploit contract code.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGoodSamaritan{
    function requestDonation()external returns (bool);
}

contract ExploitGoodSamaritan{
    ////////////////////////
    //////Errors////////////
    ////////////////////////

    error NotEnoughBalance();

    ///////////////////////
    ///State Variables/////
    ///////////////////////

    IGoodSamaritan samaritan;

    constructor(address _addr){
        samaritan=IGoodSamaritan(_addr);
    }


    function Exploit()public{
        samaritan.requestDonation();
    }

    function notify(uint256 _amount)public payable{
        if(_amount==10){
            revert NotEnoughBalance();
        }

    }

}
```

Deploy this contract and call the Exploit() function. Once the call is done successfully the challenge will be solved.

Hope you enjoyed this challenge.

### Key takeaways

We should not write our contract logic based on errors unless we are sure that the errors can only be thrown by our contract itself or in the way we intended. If our contract logic depends on errors and makes calls to other contracts, then malicious actors may revert with the same error and exploit our contract logic.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
