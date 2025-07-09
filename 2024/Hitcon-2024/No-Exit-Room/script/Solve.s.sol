// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/Beacon.sol";
import "../src/Channel.sol";
import "../src/Protocol.sol";
import "../src/Room.sol";
import "../src/Setup.sol";

contract AttackSetup{
    int256[] public xvs_alice;
    int256[] public xvs_bob;
    int256[] public xvs_david;
    
    Setup setup;

    constructor(address _addr){
        setup=Setup(_addr);
    }

    function alice_addr()public view returns (address){
        return address(setup.alice());
    }

    function bob_addr()public view returns (address){
        return address(setup.bob());
    }

    function david_addr()public view returns (address){
        return address(setup.david());
    }
    function evaluateLagrange(int256[] memory xValues, int256[] memory yValues, int256 x)
        external
        pure
        returns (int256 ret)
    {
        for (uint256 i = 0; i < yValues.length;) {
            ret = 1;
            unchecked {
                i += 1;
            }
        }
    }

    function evaluate(int256[] memory polynomial, int256 x) external pure returns (int256 ret) {
        int256 power = 1;
        for (uint256 i; i < polynomial.length;) {
            ret =1;
            power *= x;
            unchecked {
                i += 1;
            }
        }
    }
    
    function setpuzzlestatus(int256 num)public {
        setup.commitPuzzle(num);
    }

    function changebeacon_addr(address _addr)public{
        setup.beacon().update(_addr);
    }

    function sendMessageAlice(address to,int256 x)public{
        setup.alice().request(to,x);
        xvs_alice.push(x);
    }
    function sendMessageBob(address to,int256 x)public{
        setup.bob().request(to,x);
        xvs_bob.push(x);
    }
    function sendMessageDavid(address to,int256 x)public{
        setup.david().request(to,x);
        xvs_david.push(x);
    }    

    function selfMessageAlice(int256 x)public{
        setup.alice().selfRequest(x);
        xvs_alice.push(x);
    }
    function selfMessageBob(int256 x)public{
        setup.bob().selfRequest(x);
        xvs_bob.push(x);
    }
    function selfMessageDavid(int256 x)public{
        setup.david().selfRequest(x);
        xvs_david.push(x);
    }

    function solveroomAlice()public{
        setup.alice().solveRoomPuzzle(xvs_alice);
    }

    function solveroomBob()public{
        setup.bob().solveRoomPuzzle(xvs_bob);
    }

    function solveroomDavid()public{
        setup.david().solveRoomPuzzle(xvs_david);
    }

    function checkSolveStatus()public view returns(bool){
        return setup.isSolved();
    }

    function alicesolved()public view returns(bool){
        return setup.alice().isSolved();
    }

    function bobsolved()public view returns(bool){
        return setup.bob().isSolved();
    }
    function davidsolved()public view returns(bool){
        return setup.david().isSolved();
    }

    function alicehacked()public view returns(bool){
        return setup.alice().isHacked();
    }
    function bobhacked()public view returns(bool){
        return setup.bob().isHacked();
    }
    function davidhacked()public view returns(bool){
        return setup.david().isHacked();
    }
}