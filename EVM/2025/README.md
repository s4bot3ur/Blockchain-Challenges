# 2025 Challs

## Setting Up Challenges Locally
Follow the steps below to set up and solve the challenges locally.


1. Deploy a Challenge
Use the following command to deploy the challenge you want to solve:

```bash
make deploy CTF=$CTF_NAME CHALL=$CHALL_NAME
```
- CTF_NAME is the folder name of the CTF.
- CHALL_NAME is the folder name of the specific challenge within that CTF.
2. Run the Exploit Script
Use the command below to run the exploit script:
```bash
make solve CTF=$CTF_NAME CHALL=$CHALL_NAME 
```
By default, this runs the script located at:
`script/CTF_NAME/CHALL_NAME/Exploit.s.sol:Exploit`

## Notes
- You can find the reference solution for each challenge at:
`script/CTF_NAME/CHALL_NAME/solution/Exploit.s.sol`


