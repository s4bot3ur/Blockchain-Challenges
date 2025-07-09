# Writeup for Elevator

- Hello h4ck3r, welcome to the world of smart contract hacking. Solving the challenges from Ethernaut will help you understand Solidity better. For each challenge, a contract will be deployed, and an instance will be provided. Your task is to interact with the contract and exploit its vulnerabilities. Don't worry if you are new to Solidity and have never deployed a smart contract before. You can learn how to deploy a contract using Remix [here](https://youtu.be/3xNFZI8Ste4?si=i3cWN87OpX85zp6k).

### Challenge Description

This elevator won't let you reach the top of your building. Right?

### Contract Explanation

Click [here](./src/contracts/Elevator.sol) to view the contract.

If you feel like you understand the contract, you can move to the [exploit](#exploit) part. If you are a beginner, please go through the Contract Explanation as well. It will help you understand Solidity better.

If we see the code, we can observe an `interface` named `Building` and a `contract` named `Elevator`.

In a Solidity contract, an interface is a list of function definitions without implementation. This can be used when we want to interact with deployed contracts. Observe the following example to understand more.

```solidity

contract deployed_Contract{
    uint8 Number=10;
    function increment_Number()public {
        Number++;
    }

    function change_Number(uint8 num)public{
        Number=num;
    }

}
```

Assume that we have deployed this contract. Now somehow we need to interact with this contract. Observe the below code.

```solidity

interface Ideployed_Contract{
    function increment_Number() external;
    function change_Number(uint8) external;
}

contract interact_With_deployed_Contract{
    Ideployed_Contract I_deployedContract;
    constructor(address _addr){
        I_deployedContract=Ideployed_Contract(_addr);
    }

    function increment()public{
        I_deployedContract.increment_Number();
    }

    function change(uint8 _num)public{
        I_deployedContract.change_Number(_num);
    }
}
```

In the above example, assume the first contract is already deployed and we want to interact with the contract. Using the above interface, we can interact with the first deployed contract. The interface will basically say that these are the functions existing on the deployed contract. Try this out in Remix.

```solidity
interface Building {
    function isLastFloor(uint256) external returns (bool);
}
```

The above is the interface of a Building contract, which means the Building contract should have the `isLastFloor()` function because using the interface, we are interacting with the contract. If the function doesn't exist in the building contract, it will revert.

In the Elevator contract, there are two state variables: `top` and `floor`. These variables are just declared in the contract but they weren't initialized in the contract. So initially, the `top` and `floor` values are set to `false` and `zero`, respectively.

```solidity
function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
```

The function `goTo()` is a public function that takes a `uint256` as an argument. The function declares a variable named `building` of type `Building`, which is the interface. It initializes `building` with the `Building` type at the address of `msg.sender`. This means that the `msg.sender` should be a contract.

Then the function makes a call to `isLastFloor()` in the `Building` contract (msg.sender contract). If it returns true, then the following lines won't execute. If it returns false, the following lines will execute.

In the next line, the **floor** variable is set to the argument passed into the `goTo()` function during the call. Then again, the function makes a call to `isLastFloor()` in the `Building` contract (msg.sender contract) and sets the return value to the **top** variable.

### Exploit

Here our task is to make the **top** variable `true`. Once we set the top variable to true, this challenge will be solved.

If we see the contract, the only place where the value of **top** is changed is in the `goTo()` function. So we need to interact with the `goTo()` function.

We should interact with the contract using another contract. In order to do that, we need to write a contract that includes the `isLastFloor()` function. This is because when we make a call to the `goTo()` function in the Elevator contract, the function sets the `building` variable using the interface of `Building` with the address as `msg.sender`.

But if we check the `goTo()` function, in order to enter the if condition and pass the condition, our `isLastFloor()` function should return `false`. Also, once it passes the if condition, it also sets **top** by making one more call to the `isLastFloor()` function. Since our task is to make top `true`, the second time our function is called, our function should return true.

So somehow we need to write logic such that when the Elevator contract first makes a call to `isLastFloor()` in our contract, it should return `false`, and the second time it should return `true`.

Click [here](./Exploit/ExploitElevator.sol) to view the exploit contract.

```solidity
function isLastFloor(uint256) public returns (bool) {
    top = !top;
    return top;
}
```

The main logic of the exploit contract is only this function. In the contract, I have declared a `bool` variable named **top** and initialized it to true. So when the `isLastFloor()` is called, top will become `false`, then it will return top (false). Then the next time `isLastFloor()` is called, top is set to true, and then it will return **top** (true).

When you deploy the Exploit contract, pass the address of the `Elevator` contract as an argument to `constructor()` and call the `Exploit()` function. Once the call is done, the challenge will be solved.

### Key Takeaways

Do not rely on external contract calls for critical logic, as they can be manipulated. Ensure that important conditions and state changes are handled within the contract itself.

 <p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
