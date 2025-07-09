// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Challenge {

    bytes32 private constant stick = 0xd4fd4e189132273036449fc9e11198c739161b4c0116a9a2dccdfa1c492006f1;
    uint256 private constant maxCodeSize = 30;
    bool public solved=false;

    /*
    Final calldata= deployedcontract+some empty bytes till 52nd byte+ 0xdeadbeef
    */

    function func(bytes memory input) external payable {

        address addr;
        bytes4 value4;
        uint256 codeSize;
        uint combined;

        assembly {
            let base := add(input, 0x20) // calculates the pointer to actual data
            let first20 := shr(96, mload(base)) // loads 32 bytes from memory and right shifts by 96bits (12 bytes)
            addr := first20 // Stores the right shifted first 20 bytes in addr

            codeSize := extcodesize(addr) 
            if gt(codeSize, maxCodeSize) {
                revert(0, 0)
            }

            let data := mload(add(input, 0x34)) //loads 32 bytes from memory starting from 0x34(52th byte)       
            value4 := data // stores first 4 bytes of data in value4.

            let value := callvalue() // stores eth sent in call
            let value1 := value 
            let value3 := 0
            let value2 := 0
            
            for { } gt(value1, 0) { value1 := shr(1, value1) } {
                value3 := shl(1, value3)
                value3 := or(value3, and(value1, 1))
            }
            let bool1 := eq(value, value3)

            value1 := value
            for { } gt(value1, 0) { value1 := and(value1, sub(value1, 1)) } {
                value2 := add(value2, 1)
            }
            let bool2 := or(lt(value2, 4), eq(value2, 3))
            combined := and(bool1, bool2)
            }
            require(combined==1, "Condition failed");

        (bool success1, bytes memory ret1) = addr.call("");
        require(success1, "Call failed");
        require(ret1.length > 0, "No return data");
        bytes1 retValue1 = bytes1(ret1[0]);
        require(retValue1 == "L", "Invalid return value");

        (bool success2, bytes memory ret2) = addr.call{value: msg.value}("");
        require(success2, "Call failed");
        require(ret2.length > 0, "No return data");
        bytes1 retValue2 = bytes1(ret2[0]);
        require(retValue2 == "M", "Invalid return value");

        bytes32 hashedValue = keccak256(abi.encodePacked(value4));
        require(hashedValue == stick, "Hash mismatch");

        solved = true;
    }
}
