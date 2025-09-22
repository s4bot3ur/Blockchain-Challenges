// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Vault.sol";
import "./Token.sol";
import "./lib/ERC20.sol";

contract VaultFactory {

    address immutable public PLAYER;
    address immutable public CHALLENGE;

	Vault[] public allVaults;

    constructor(address _player, address _challenge) {
        PLAYER = _player;
        CHALLENGE = _challenge;
    }

	function createVault(uint256[][] calldata params) external {

        assembly{
            let len := sub(calldatasize(), 4)
            if mod(len, 0x20) { mstore(0x00, "=)") revert(0x00, 0x02) }

            for {let i := 0x04} lt(i, calldatasize()) {i := add(i, 0x20)} {
                let word := calldataload(i)
                if iszero(word) {
                    mstore(0x00, "0 value not allowed")
                    revert(0x00, 0x14)
                }
            }
        }

        this.deploy(params);
	}

    function deploy(uint[][] memory params) public {
        
        for (uint256 i = 0; i < params.length; i++) {
            Token asset = new Token(PLAYER, CHALLENGE);
            Vault vault = new Vault(ERC20(asset), params[i]);

            allVaults.push(vault);
        }
	}

	function numVaults() external view returns (uint256) {
		return allVaults.length;
	}

	function vaultAt(uint256 index) external view returns (Vault) {
		return allVaults[index];
	}
}


