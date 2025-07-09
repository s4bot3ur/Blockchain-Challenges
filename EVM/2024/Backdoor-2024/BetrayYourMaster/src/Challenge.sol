// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Servant {
    function spillSecret() external view returns (bytes32);
}

// Master uses the below contract to pay your salary

contract Treasury {
    address public servant; 
    address public immutable master;
    uint256 public timesWithdrawn;
    mapping(address => uint256) servantBalances; 

    constructor(address _master) payable{
        master = _master;
    }

    function withdraw() public {
        uint256 dividend = address(this).balance / 100;

        servant.call{value: dividend}("");
        payable(master).transfer(dividend);

        timesWithdrawn++;
        servantBalances[servant] += dividend;
    }

    function BecomeServant(address _servant) external {
        servant = _servant;
    }

    function remainingTreasure() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}

contract SecretChecker {
    bool public SecretIsLeaked;
    mapping (bytes32 => bool) public attempted;

    function IKnowTheSecret(address _servant) public {
        require(!attempted[keccak256(abi.encodePacked(_servant))], "Won't give another chance :p");
        
        uint256 length;
        assembly {
            length := extcodesize(_servant)
        }
        require(length <= 20, "HaHa! try again xD");

        Servant servant = Servant(_servant);
        bytes32 encodedSecret = servant.spillSecret();
        bytes32 secret = bytes32(abi.encodePacked("I'm_L0yal;)")) >> (24 * 7);
        require(keccak256(abi.encodePacked(secret)) == keccak256(abi.encodePacked(encodedSecret)), "You don't know the secret!");

        attempted[keccak256(abi.encodePacked(_servant))] = true;
        SecretIsLeaked = true;
    }
}
