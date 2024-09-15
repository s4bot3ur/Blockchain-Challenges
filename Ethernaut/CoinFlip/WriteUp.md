# Writeup for CoinFlip

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity well. For each challenge, they will deploy the contract and provide us with the instance of that contract. Our task is to interact with the contract and exploit it. Don't worry if you are completely new to Solidity and have never deployed a smart contract before. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge

This is a coin flipping game where you need to build up your winning streak by guessing the outcome of a coin flip. To complete this level, you'll need to use your psychic abilities to guess the correct outcome 10 times in a row.

### Contract Explanation

- Click [here](/src/contracts/CoinFlip.sol) to view the contract.

- If you feel like you understood the contract you can move to the [exploit](#exploit) part. If you are a begineer please go through contract Explaination also. It will help you to understand the solidity better.

- The contract has three state variables: `uint256 consecutiveWins`, `uint256 lastHash`, and `uint256 FACTOR`. The `consecutiveWins` variable will be updated after every successful flip. The `lastHash` variable will be updated after every flip, and the `FACTOR` variable is initialized to 57896044618658097711785492504343953926634992332820282019728792003956564819968, which is the maximum value of `uint256`. It is used to calculate the `coinFlip` value.

```solidity
constructor() {
    consecutiveWins = 0;
}
```

- The above code snippet is a constructor that initializes the `consecutiveWins` variable to zero. The constructor is automatically called during the deployment of the contract.

```solidity
function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
        revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
        consecutiveWins++;
        return true;
    } else {
        consecutiveWins = 0;
        return false;
    }
}
```

- The `flip()` function is a public function that takes a boolean parameter `guess` as input and returns `true` if the flip is successful, otherwise it will return `false`.

- First, it initializes the `blockValue` to the blockhash of the previous block. They are using the previous blockhash because the blockhash of the current block cannot be determined until it is mined or validated. `block.number` returns the current block number. By subtracting 1 from the current block number, they get the hash value of the previous block.

- Then, the function checks if the `lastHash` is equal to `blockValue` or not. The `lastHash` is updated after each flip, regardless of success or failure.

- After that check, it updates the `lastHash` value to `blockValue`. This ensures that `flip()` can only be called once in a block. If we call `flip()` with some value and then call it again within the same block, it will revert because the `lastHash` is already updated to `blockValue`. Since `blockValue` is the same in both calls and `lastHash` will match exactly with the `blockValue` set in the first call, it will revert.

- Next, the function calculates the `coinFlip` value by dividing `blockValue` by `FACTOR`. `FACTOR` is a `uint256` initialized with 2^255, which is 32 bytes. Since the `blockhash` is also 32 bytes, when divided by `FACTOR`, it will return either 0 or 1.

- Then, the function initializes the `side` variable to `true` if `coinFlip` is 1, otherwise it is initialized to `false`.

- Finally, it checks if the value of `side` is equal to `guess`. If they are the same, `consecutiveWins` is incremented by 1 and the function returns `true`. If they are not the same, `consecutiveWins` is set to 0 and the function returns `false`.

### Exploit

- By examining the contract, it becomes apparent that the value of `side` is primarily determined by `blockValue`. If we can somehow obtain the `blockValue` before calling the function, we can easily calculate the guess value and pass it as an argument to the `flip()` function.

- When interacting with a smart contract, our interactions are conducted through transactions. Calling a function that modifies the state of a deployed contract is considered a transaction. Changing the state involves altering the values of state variables.

- In the Ethereum Virtual Machine (EVM), if we call a function of a smart contract that in turn calls another contract's function, both calls will be broadcasted to the Ethereum network as a single transaction and will be mined in the same block.

- Based on this understanding, we can conclude that we can calculate the guess value before calling the `flip()` function and then pass it as an argument to the function.

- In this challenge, we do not interact with the contract using the console. Instead, we need to write an Exploit contract and deploy and interact with it using Remix, an online Solidity IDE.

- If you are unfamiliar with Remix, you can refer to this video tutorial: [Remix Tutorial](https://www.youtube.com/watch?v=WmeWbo7wzGI).

- Here is an example of an exploit contract:

```solidity
function exploit() public {
    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlip = blockValue / FACTOR;
    bool guess = coinFlip == 1 ? true : false;
    bool success = CoinFlip.flip(guess);
    require(success, "Exploit failed");
}
```

- As mentioned earlier, we calculate the `blockValue` and `coinFlip` values in the same way as the `flip()` function in the CoinFlip contract.

- Once the guess value is calculated, we call the `flip()` function of the CoinFlip contract with the guess value. Since the `exploit()` function calls the `flip()` function, both calls will be broadcasted as a single transaction, ensuring that the `blockValue` remains the same and the `flip()` function succeeds.

- If the `flip()` function fails, our exploit function call will be reverted. However, if our exploit contract is implemented correctly, no reverts will occur.

- To achieve 10 consecutive wins, we need to call the `exploit()` function 10 times to pass the level.

- You can click [here](/Exploit/ExploitCoinFlip.sol) to view the exploit contract. In Remix, during deployment, we need to provide the address of the `CoinFlip` contract as an argument to the constructor of the exploit contract.

- Once the 10 calls are completed, submit the level instance.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
