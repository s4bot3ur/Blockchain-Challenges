# Writeup for DoubleEntryPoint

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. Each challenge involves deploying a contract and exploiting its vulnerabilities. If you're new to Solidity and haven't deployed a smart contract before, you can learn how to do so using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

This level features a CryptoVault with special functionality, the sweepToken function. This is a common function used to retrieve tokens stuck in a contract. The CryptoVault operates with an underlying token that can't be swept, as it is an important core logic component of the CryptoVault. Any other tokens can be swept.

The underlying token is an instance of the DET token implemented in the DoubleEntryPoint contract definition and the CryptoVault holds 100 units of it. Additionally the CryptoVault also holds 100 of LegacyToken LGT.

In this level you should figure out where the bug is in CryptoVault and protect it from being drained out of tokens.

The contract features a Forta contract where any user can register its own detection bot contract. Forta is a decentralized, community-based monitoring network to detect threats and anomalies on DeFi, NFT, governance, bridges and other Web3 systems as quickly as possible. Your job is to implement a detection bot and register it in the Forta contract. The bot's implementation will need to raise correct alerts to prevent potential attacks or bug exploits.

Things that might help:

How does a double entry point work for a token contract?

### Key Concepts To Learn

We know that once we deploy the contract without implementing upgradability, the contract cannot be modified. Assume you have deployed an ERC20 contract that has become very famous and your token has significant value. Now, you have found a bug in your contract. How are you going to fix it? There is no way to fix the vulnerability directly. However, if we have a pause function to pause the functionality of the contract, we can then shift the entire balances data to a new contract.

Instead, if we implement bot detection functionality, we can mitigate these risks. Whenever a function in the token contract is called, it should check with the bot detection contract (if deployed); otherwise, it should execute the function as normal. If we discover a vulnerability, we can deploy a bot contract to manage the situation and revert calls if someone attempts to exploit the contract.

The below is the example.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


contract contract_one {

    uint256 public balance = 2**256 - 1; // Initializing balance to max uint256

    function deposit(uint256 a) public Notify payable {
        require(a<=msg.value,"You cannot deposit more than what you paid");
        balance += a;
    }

}

```

If you see the contract `contract_one`, it is a basic contract that stores deposits. Whenever someone calls the `deposit()` function by sending some `ether`, they need to pass the amount they are paying to the contract as an argument to the function. Whenever someone deposits the ether, it will increase the balance by the deposited value. However, if we look at the compiler version, it is 0.6.0, which is vulnerable to overflows. So, after many deposits, when the balance reaches the maximum value of `uint256` (2\*\*256 - 1), the next time someone deposits, the `balance` variable will start from zero again.

Inorder to demonstrate the exploit i just set the balance to 2\*\*256-1. Now you just deploy the contract and call deposit() function by sending 10 wei. After the call you will notice the balance becoming to 9.

Now imagine during writing and deploying our contract we implemented some code for handling exploits for later use. check the below example.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IBot {
    function Validatedata(bytes calldata data) external;
}

interface Icontract_one {
    function RaiseAlert() external;
    function balance() external view returns (uint);
}

contract contract_one {
    address owner;
    uint256 public balance = 2**256 - 1; // Initializing balance to max uint256
    address Bot_Address;
    mapping(address => uint256) botraisedAlerts;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function deposit(uint256 a) public Notify payable {
        require(a<=msg.value,"You cannot deposit more than what you paid");
        balance += a;
    }

    //////////////////////////////////
    ///// Handling Exploit ///////////
    //////////////////////////////////

    modifier Notify() {
        if (Bot_Address == address(0)) {
            _;
            return;
        }
        uint256 current_Alerts = botraisedAlerts[Bot_Address];
        bytes memory data = msg.data;
        IBot(Bot_Address).Validatedata(data);
        _;
        if (botraisedAlerts[Bot_Address] > current_Alerts) {
            revert("You have been caught");
        }
    }

    function set_bot(address New_bot) public onlyOwner {
        Bot_Address = New_bot;
    }

    function RaiseAlert() external {
        if (Bot_Address == msg.sender) {
            botraisedAlerts[msg.sender] += 1;
        }
    }
}


contract Bot {
    function add(uint256 a, uint256 b) internal pure returns (bool) {
        uint256 c = a + b;
        return c >= a;
    }
    function Validatedata(bytes calldata data) external {
        uint256 current_balance=Icontract_one(msg.sender).balance();
        (uint256 a) = abi.decode(data[4:], (uint256));

        if (!add(a, current_balance)) {
            Icontract_one(msg.sender).RaiseAlert();
        }
        balance += a;
    }
}


```

The contract `contract_one` will work the same as the previous example unless we implement the bot. In `contract_one`, when we call the `deposit()` function, it will execute the modifier `Notify`. The modifier `Notify` will check if the `Bot_Address` is set or not. If the `Bot_Address` is the zero address, then the modifier will return without executing any logic, and the `deposit()` function will execute.

However, if the `Bot_Address` is set to some address, then the modifier `Notify` will set the current number of alerts raised by the bot to `current_Alerts`. It will then store the current calldata (`msg.data`) in the `data` variable. After that, it will make a call to `Validatedata()` in the bot contract and then execute the `deposit()` logic. Once the `deposit()` call is completed, the logic in the modifier after `_` will execute. In the modifier after `_;`, it will check whether the current alerts are more than the previous alerts or not. If the alerts are more, it will revert; otherwise, the `deposit()` will be successful.

If a modifier is used in a function, then the modifier will be executed two times during the function call. The modifier will be executed before the execution of the function and after the execution of the function. In the modifier, the logic before `_;` will be executed before executing the function call, and the logic after `_;` will be executed after executing the function call.

Now we found the bug in our deployed contract. The bug is due to overflow. We can implement a bot contract to handle the overflow. If we check the `Notify` modifier in `contract_one`, it calls a function `Validatedata()` in the bot contract. This means that when implementing the bot contract, we should implement a function named `Validatedata()` in the bot contract. In the Validatedata function, we need to check if someone is trying to exploit the bug. If someone is trying to exploit the bug, the bot contract should call `RaiseAlert()` in `contract_one`. The `Notify` modifier will then handle the alerts and revert the call.

Now, since the bug is due to overflow, we need to write logic to overcome this issue. The `Notify` modifier will pass the calldata of `deposit()` to `Validatedata()`. The calldata will consist of the function selector of `deposit(uint256)` and the argument passed. We need to get the depositing amount from the data passed and then add the depositing amount and the current balance of the contract to check whether overflow is happening or not. If overflow happens, then `Validatedata()` will raise an alert; otherwise, the `deposit()` function will execute as expected.

Try the example to understand in detail.

### Contract Explanation

If you understand the contract, you can move on to the [exploit](#exploit) part. If you're a beginner, please read the Contract Explanation to gain a better understanding of Solidity.

Click [here](./src/contracts/DoubleEntryPoint.sol) to view the contract source code.

<details>
<summary>Click to view the contract explanation</summary>

```solidity
interface DelegateERC20 {
    function delegateTransfer(address to, uint256 value, address origSender) external returns (bool);
}

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}

```

The challenge uses the above three interfaces. The interface `DelegateERC20` is used in the `LegacyToken` contract. The interface `IDetectionBot` is used in the `Forta` contract to call the detection bot set by the user. The interface `IForta` is used by the `Forta` contract to implement all the functions of `IForta` in the `Forta` contract.

```solidity
contract Forta is IForta {
    mapping(address => IDetectionBot) public usersDetectionBots;
    mapping(address => uint256) public botRaisedAlerts;

    function setDetectionBot(address detectionBotAddress) external override {
        usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
    }

    function notify(address user, bytes calldata msgData) external override {
        if (address(usersDetectionBots[user]) == address(0)) return;
        try usersDetectionBots[user].handleTransaction(user, msgData) {
            return;
        } catch {}
    }

    function raiseAlert(address user) external override {
        if (address(usersDetectionBots[user]) != msg.sender) return;
        botRaisedAlerts[msg.sender] += 1;
    }
}
```

Forta is a contract where users can register and set a detection bot to ensure that contracts owned by the user work as expected. Suppose you deployed your contract and implemented Forta in your contract. Later, if you find a bug in your contract, you can write a Forta bot contract to ensure that the bug won't be exploited. The Forta bot contract will handle the bug.

The contract has two state variables named `usersDetectionBots` and `botRaisedAlerts`. `usersDetectionBots` is a **mapping** of **address** to **IDetectionBot** and `botRaisedAlerts` is a **mapping** of **address** to **uint256**.

```
function setDetectionBot(address detectionBotAddress) external override {
    usersDetectionBots[msg.sender] = IDetectionBot(detectionBotAddress);
}
```

This function `setDetectionBot()` takes an argument of type **address** as input and sets the `usersDetectionBots` of `msg.sender` (caller) to the passed **address**. When you find a `bug` in your contract, and if the `bug` can be fixed with a bot contract, you create the `bot contract` and call `setDetectionBot()` by passing the **address** of the `bot contract`.

```solidity
function notify(address user, bytes calldata msgData) external override {
    if (address(usersDetectionBots[user]) == address(0)) return;
    try usersDetectionBots[user].handleTransaction(user, msgData) {
        return;
    } catch {}
}
```

The function `notify()` takes an **address** and **bytes** as input. The **address** is the address of the user, and the **bytes** data is calldata sent by the caller `(AKA msg.sender)`. The function checks if the user has any `bots`. If the user has no bot, the function returns. If the user has a `bot`, the function calls the `handleTransaction()` function in the `bot contract`.

In the example i explained you can consider user as owner.

```
function raiseAlert(address user) external override {
    if (address(usersDetectionBots[user]) != msg.sender) return;
    botRaisedAlerts[msg.sender] += 1;
}
```

The function `raiseAlert()` takes an argument of type **address**, which is the address of the **user**. It then checks if the caller of `raiseAlert()` is the `bot contract` of the `user`. If not, it will return; otherwise, it will increase the `botRaisedAlerts` of the `bot contract` by 1.

In our example, once you write the bot contract to handle the bug, if someone tries to exploit the bug, our bot contract will catch the exploit and raise an alert. Then, using a modifier, we can handle the function by comparing `botRaisedAlerts` before and after call.

I hope this make sense if you are not clear with anything you can ask questions in Discussions.

```solidity
contract CryptoVault {
    address public sweptTokensRecipient;
    IERC20 public underlying;

    constructor(address recipient) {
        sweptTokensRecipient = recipient;
    }

    function setUnderlying(address latestToken) public {
        require(address(underlying) == address(0), "Already set");
        underlying = IERC20(latestToken);
    }

    /*
    ...
    */

    function sweepToken(IERC20 token) public {
        require(token != underlying, "Can't transfer underlying token");
        token.transfer(sweptTokensRecipient, token.balanceOf(address(this)));
    }
}
```

This contract has two state variables: `sweptTokensRecipient` and `underlying`. `sweptTokensRecipient` is of type **address**, and `underlying` is of type **IERC20**, which means the underlying contract will have all the functions in the IERC20 interface.

```solidity
constructor(address recipient) {
    sweptTokensRecipient = recipient;
}
```

The `constructor()` takes an argument of type **address** as input. It sets the `sweptTokensRecipient` to the address passed to the `constructor()` during deployment.

```solidity
function setUnderlying(address latestToken) public {
    require(address(underlying) == address(0), "Already set");
    underlying = IERC20(latestToken);
}
```

The function `setUnderlying()` takes an argument of type **address** as input and checks whether the `underlying` token is already set or not. If it is not set, then it will set the `underlying` to the address passed during the function call.

```solidity
function sweepToken(IERC20 token) public {
    require(token != underlying, "Can't transfer underlying token");
    token.transfer(sweptTokensRecipient, token.balanceOf(address(this)));
}
```

The function `sweepToken()` will take an argument of type **IERC20** (token) as input and check if the token passed is the `underlying` token or not. If it is the underlying token, then the function will `revert`. If the token passed is not the underlying token, then the function will call the `transfer()` function in the token contract, transferring the total balance of tokens in the contract to `sweptTokensRecipient`.

```solidity
contract LegacyToken is ERC20("LegacyToken", "LGT"), Ownable {
    DelegateERC20 public delegate;

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
        delegate = newContract;
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        if (address(delegate) == address(0)) {
            return super.transfer(to, value);
        } else {
            return delegate.delegateTransfer(to, value, msg.sender);
        }
    }
}
```

The above contract is an implementation of ERC20 contract. All the functionalities will same except the mint() and transfer() function.

The contract has a state variable `delegate` of type **DelegateERC20** interface.

```solidity
function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
}
```

The function `mint()` takes two arguments of type **address** (to) and **uint256** (amount) as input. It can only be called by the `owner` of the contract because when the function is called, it will execute the `onlyOwner` modifier, which is defined in the `Ownable` contract.

```solidity
function delegateToNewContract(DelegateERC20 newContract) public onlyOwner {
    delegate = newContract;
}
```

The function `delegateToNewContract()` takes an argument of type **DelegateERC20** and and sets the `delegate` to address passed in function call.

```solidity

function transfer(address to, uint256 value) public override returns (bool) {
    if (address(delegate) == address(0)) {
        return super.transfer(to, value);
    } else {
        return delegate.delegateTransfer(to, value, msg.sender);
    }
}
```

The function `transfer()` will take two arguments of type **address** (to) and **uint256** (value) as inputs. It will call the `transfer()` function in the `ERC20` contract if the address of `delegate` is zero; otherwise, it will call the `delegateTransfer()` function in the `delegate` (DelegateERC20) contract. It will return the value returned by one of the above calls.

```solidity
contract DoubleEntryPoint is ERC20("DoubleEntryPointToken", "DET"), DelegateERC20, Ownable {
    address public cryptoVault;
    address public player;
    address public delegatedFrom;
    Forta public forta;

    constructor(address legacyToken, address vaultAddress, address fortaAddress, address playerAddress) {
        delegatedFrom = legacyToken;
        forta = Forta(fortaAddress);
        player = playerAddress;
        cryptoVault = vaultAddress;
        _mint(cryptoVault, 100 ether);
    }

    modifier onlyDelegateFrom() {
        require(msg.sender == delegatedFrom, "Not legacy contract");
        _;
    }

    modifier fortaNotify() {
        address detectionBot = address(forta.usersDetectionBots(player));

        // Cache old number of bot alerts
        uint256 previousValue = forta.botRaisedAlerts(detectionBot);

        // Notify Forta
        forta.notify(player, msg.data);

        // Continue execution
        _;

        // Check if alarms have been raised
        if (forta.botRaisedAlerts(detectionBot) > previousValue) revert("Alert has been triggered, reverting");
    }

    function delegateTransfer(address to, uint256 value, address origSender)
        public
        override
        onlyDelegateFrom
        fortaNotify
        returns (bool)
    {
        _transfer(origSender, to, value);
        return true;
    }
}

```

The contract `DoubleEntryPoint` is an implementation of `ERC20` token. The name of the token implemented in `DoubleEntryPoint` is `DET`.

The contract has state variales `cryptoVault` (address), `player` (address), `delegatedFrom` (address), `forta` (Forta).

```solidity
constructor(address legacyToken, address vaultAddress, address fortaAddress, address playerAddress) {
    delegatedFrom = legacyToken;
    forta = Forta(fortaAddress);
    player = playerAddress;
    cryptoVault = vaultAddress;
    _mint(cryptoVault, 100 ether);
}
```

The constructor takes arguments of type **address** (legacyToken), **address** (vaultAddress), **address** (fortaAddress), **address** (playerAddress). It sets the `delegatedFrom` to legacyToken, `forta` to instance of Forta, `player` to playerAddress, `cryptoVault` to vaultAddress. Then it mint's `cryptoVault` `100 * 10**18` tokens.

```solidity
modifier onlyDelegateFrom() {
    require(msg.sender == delegatedFrom, "Not legacy contract");
    _;
}

```

The modifier `onlyDelegateFrom()` will check if the `msg.sender` (caller) is delegatedFrom or not. If it is, then it will continue executing the function; otherwise, it will revert the function call in which the `onlyDelegateFrom()` modifier is used.

```solidity
modifier fortaNotify() {
    address detectionBot = address(forta.usersDetectionBots(player));

    // Cache old number of bot alerts
    uint256 previousValue = forta.botRaisedAlerts(detectionBot);
    // Notify Forta
    forta.notify(player, msg.data);
    // Continue execution
    _;

    // Check if alarms have been raised
    if (forta.botRaisedAlerts(detectionBot) > previousValue) revert("Alert has been triggered, reverting");
}
```

The modifier `fortaNotify()` will take the detection bot of the `player` and store the number of **alerts** raised by that bot in `previousValue`. Then it will call `notify()` in the `Forta` contract with arguments as the player's address and `msg.data` (calldata). It will then complete the execution of the function in which the `fortaNotify()` modifier is used. Once the function call is completed, it will compare the bot raised alerts before and after the function call. If the bot raised alerts after the call are more than before the function call, the function call will be reverted.

```solidity
function delegateTransfer(address to, uint256 value, address origSender)public override onlyDelegateFrom fortaNotify        returns (bool){
    _transfer(origSender, to, value);
    return true;
}
```

The function `delegateTransfer()` takes arguments of type **address** (to), **uint256** (value), and **address** (origSender) as input. It will execute the modifiers `onlyDelegateFrom` and `fortaNotify`. If the modifiers execute successfully, then the function will transfer `DET` tokens from `origSender` to the recipient (`to`) by calling the `_transfer()` function in `ERC20` contract. After the call the function will return true.

</details>

### Exploit

According to the challenge, we need to make sure that the `CryptoVault` contract works as expected. It should not allow DET tokens to be swept.

We are able to call `sweepToken()` by passing the address of LegacyToken (LGT) tokens. Then the `sweepToken()` will make a call to `transfer()` in the `LegacyToken` contract. The `LegacyToken` contract has a state variable named `delegate`. If the `delegate` is set to an address, then the `transfer()` function in `LegacyToken` will call the `delegateTransfer()` function at the `delegate` address.

If we check the `DoubleEntryPoint` contract, it is implementing the function `delegateTransfer()`. So in `LegacyToken`, the `delegate` is set to the address of `DoubleEntryPoint`. When we call `sweepToken()`, it makes a call to `transfer()` in `LegacyToken`, and the `transfer()` in `LegacyToken` calls the `delegateTransfer()` in `DoubleEntryPoint`. The `delegateTransfer()` will send tokens from the `CryptoVault` contract to `sweptTokensRecipient` in `CryptoVault`. But if we see the tokens which `delegateTransfer()` is transferring, it is DET tokens. According to the challenge, no one should be able to withdraw DET tokens from `CryptoVault`. So now we need to write a contract to prevent the exploit.

Now let's write a contract to prevent this exploit. Our logic will be simple: when the `delegateTransfer` is called, we will check if the `origSender` is the address of `CryptoVault` or not. If it is `CryptoVault`, then the contract will raise an alert.

The below is the contract to prevent this exploit.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;
    function notify(address user, bytes calldata msgData) external;
    function raiseAlert(address user) external;
}


contract PreventDoubleEntry{
    IForta forta;
    constructor(){
        forta=IForta(//__YOUR_FORTA_ADDRESS__);
    }
    function handleTransaction(address user, bytes calldata msgData) external{
        (,,address _origSender) = abi.decode(msgData[4:], (address, uint256, address));
        if(_origSender==//__CRYPTO_VAULT_ADDRESS__){
            forta.raiseAlert(user);
        }
    }

}
```

Now open the console and enter the following commands to get the `FORTA` address and the `CRYPTOVAULT` address.

```javascript
> await contract.cryptoVault()
```

```javascript
> await contract.forta()
```

Set the `cryptovault` address and `forta` address in `PreventDoubleEntry` and deploy it, and then call the `setDetectionBot()` function in the `Forta` contract by passing the address of `PreventDoubleEntry`. Remember that the player in `DoubleEntryPoint` will be our wallet address. So when the `notify()` function in `Forta` checks for the bot, it will check the bots of the user (player). When `setDetectionBot()` is called, it will set the bot of `msg.sender` to the address passed. Therefore, we must call from our account to set the bot instead of calling from the bot contract itself.

You cal load the the deployed Forta contract in remix by the compiling the Forta contract then copy the Forta address and click At Address. Check the below image.

<p align="center">
  <img src="img/img1.png" />
</p>

Once you click "At Address" by entering the address of the Forta contract, it will load all the functions of the Forta contract. Then call the `setDetectionBot()` function by passing the address of `PreventDoubleEntry`. Once the call is done, the challenge will be solved.

That's it for this challenge. Hope you liked the writeup.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
