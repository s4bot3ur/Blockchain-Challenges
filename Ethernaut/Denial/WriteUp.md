# Writeup for Denial

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

This is a simple wallet that drips funds over time. You can withdraw the funds slowly by becoming a withdrawing partner.

If you can deny the owner from withdrawing funds when they call withdraw() (while the contract still has funds, and the transaction is of 1M gas or less), you will win this level.

### Contract Explanation

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

<details>
<summary>Click to view the source contract</summary>

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value: amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

```

I hope you are good at understanding contracts. If you are unable to understand the contract, then stop here and try out all the challenges on your own without going through any write-up. If there are any new things in the contract, I will explain those types of contracts.

</details>

### Key Concepts To Learn

In Solidity, we use assert and require to check certain conditions are met or not. But we need to understand the major difference between assert and require.

`assert`: This is used to check for conditions that should never occur in a correctly functioning contract. If an assert fails, it indicates a serious issue in the code, such as an internal error or a bug. It is typically used to validate invariants or to check for conditions that should always be true. Below is an example of assert.

`require`: This is used for input validation and to ensure certain conditions are met before executing further code. It can check for things like valid user inputs, sufficient funds, or conditions related to external calls. If a require statement fails, it reverts the transaction and provides an error message.

Below is an example that gives much clarity about the usage difference between `assert` and `require`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ExampleContract {
    uint256 public value;

    // Function to set the value with input validation
    function setValue(uint256 _value) public {
        // Use require to validate input
        require(_value > 0, "Value must be greater than 0");
        value = _value;
    }

    // Function to increment the value
    function incrementValue() public {
        // Use assert to check internal logic
        uint256 oldValue = value;
        value += 1;

        // Ensure that value has increased correctly
        assert(value == oldValue + 1);
    }
}

```

The major difference between `assert()` and `require()` is that if the condition in `require()` fails, it will revert all the changes made and also refund the gas offered for the transaction. But if the `assert()` fails, it will consume all the gas and revert all the state changes.

### Exploit

Now our task is to make the contract deny the transactions that call the withdraw() function.

```solidity
function withdraw() public {
    uint256 amountToSend = address(this).balance / 100;
    // perform a call without checking return
    // The recipient can revert, but the owner will still get their share
    partner.call{value: amountToSend}("");
    payable(owner).transfer(amountToSend);
    // keep track of last withdrawal time
    timeLastWithdrawn = block.timestamp;
    withdrawPartnerBalances[partner] += amountToSend;
    }
```

If we see the withdraw() function, we can observe that whenever someone calls the withdraw() function, it will send contract balance/100 to the partner as well as the owner. If we set our address as the partner, we will become the partner and it will send the ether.

```solidity
function setWithdrawPartner(address _partner) public {
    partner = _partner;
}
```

By calling the above function, we can set the partner to whatever address we pass during the function call.

If we set the partner address as EOA (Externally owned account), it won't be useful because we can't deny. We need to write an `Exploit` contract, and we need to set the Exploit contract as the partner.

Since the withdraw() function is making a low-level call during the call, it will send the entire gas to the partner. Once the partner transaction is completed, the remaining gas is returned to the withdraw() function, and the remaining gas is used to execute the next lines.

Since the withdraw() function is making a low-level call to the partner (exploit contract), in our exploit contract, if we somehow consume all the gas, then there won't be enough gas to execute the transfer() function, and it will revert the entire function call of withdraw().

When a contract makes a low-level call to another contract, there should be a `receive()` function in the called contract. In the `receive()` function, we can write whatever code we want. So if we write an `assert()` condition that will always fail, then the `assert()` will consume all the gas and revert. The below is the exploit contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


contract ExploitDenial{

    receive() external payable {
        assert(false);
    }
}
```

Deploy this contract and open the console and enter the following

```javascript
> await contract.setWithdrawPartner("YOUR__EXPLOIT__CONTRACT__ADDRESS")
```

Once the transaction is completed, just submit the instance.

### Key Takeaways

### Key Takeaways

The Denial contract is currently using a low-level call to send ether. However, if it were to use the `transfer()` or `send()` function instead, the exploit described above would not be possible. This is because a low-level call sends the entire gas during the call, whereas `send()` and `transfer()` only send 2300 units of gas, which is sufficient for the transfer of ether.

If the contract were to use `transfer()`, the function would only send 2300 units of gas, which is enough for transferring ether. After the transfer, there wouldn't be much room for additional operations. If we were to attempt any operations in the `receive()` function of our contract, the `transfer()` would be reverted. Although the revert would only return false, it wouldn't have any effect on the main function call.
