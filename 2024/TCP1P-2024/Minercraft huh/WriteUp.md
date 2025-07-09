# Writeup for Minercraft Huh

- Hello h4ck3r, welcome to the world of smart contract hacking. In order to understand this writeup you need to understand foundry.

### Challenge Description

Say, everyone knows minecraft right?
The game about mining block after block after block after block.....

NOTE!
You only need to spawn an instance, no need to press the "Flag" button.
The isSolved() function will always return false afterall.

### Exploit

In the challenge description, the author mentioned that the `isSolved()` function will always return false. He also mentioned that there is no need to press the FLAG button to get the flag.

In general a challenge instance for blokchain challenges in TCP1P ctf is as follows

<p align="center">
  <img src="img/img1.png" />
</p>

For every challenge, there will be a Setup contract, and the Setup contract will have an `isSolved()` function. If we make the `isSolved()` function return true, we can get the flag. If we are sure we have solved the challenge, we can hit the flag button in the above instance. It will check whether the `isSolved()` function of the Setup contract is returning true or false. If it returns true, it will give us the flag.

But in this challenge, the author specifically mentioned that there is no need to hit the flag button to get the flag, which means the flag is stored somewhere in the blockchain. It can be stored in any contract deployed on the blockchain corresponding to the given RPC URL, or it might be sent in any transaction as data. So, if we go through all the transactions in every block, we might get the flag. Basically, here we are using the power of transparency in the blockchain.

First let's check what is the current block number.

```shell
$ cast block-number --rpc-url http://45.32.119.201:44555/e915a9dc-73f1-476a-8ffb-bfece67e5eca
```

This has returned 8, which means there were 8 blocks mined. Since we haven't made any transactions, the block number remains the same. These 8 blocks' transactions were done while creating the instance. The flag must be in one of the transactions in one of the 8 blocks.

Now, let's go through each block and the corresponding transactions.

```shell
$ cast block 0 http://45.32.119.201:44555/e915a9dc-73f1-476a-8ffb-bfece67e5eca
```

<p align="center">
  <img src="img/img2.png" />
</p>

The zeroth block doesn't have any transactions.

<p align="center">
  <img src="img/img3.png" />
</p>

The first block has a single transaction. Now lets check more details about transaction

<p align="center">
  <img src="img/img4.png" />
</p>

```shell
$ cast tx --rpc-url http://45.32.119.201:44555/e915a9dc-73f1-476a-8ffb-bfece67e5eca 0x97ae009b944f46aa80772e19f2c28c2261d530d06859331915d87036e5e70638
```

In the transaction details, we need to focus only on the input data because whatever the transaction is—whether it is creating a contract, interacting with a contract, or sending some ETH to another person everything will contain some input data.

In the above transaction there is a bunch of hex data. It is probably a contract but still why to take the change let's decode it to ASCII using [cyberchef](<https://gchq.github.io/CyberChef/#recipe=From_Hex('Space')>). The output is as follows.

<p align="center">
  <img src="img/img5.png" />
</p>

In the same way, we need to find transactions in each block and decode the input in each transaction.

In the search for the flag, I have found some fake flags and some texts.

fake-flag 1: TCP3P{this_is_one_p_not_three_p}  
text 1: Oh, I changed my mind again!  
text 2: Nah, that does not sound good  
text 3: TCP1P....

So finally in block number 6 i got the original flag.

<p align="center">
  <img src="img/img6.png" />
</p>

<p align="center">
  <img src="img/img7.png" />
</p>

<p align="center">
  <img src="img/img8.png" />
</p>

**Flag:** `TCP1P{running_through_some_blocks_have_you?}`

### Key Takeaways

We shouldn't store any sensitive information on the blockchain. Since the blockchain is meant for transparency, everyone can see each transaction.

<p style="text-align:center;">***<strong>Hope you enjoyed this write-up. Keep on hacking and learning!</strong>***</p>
