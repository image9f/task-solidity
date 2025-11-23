// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract FlipStr {
    function flipstring(string memory str) public pure returns (string memory) {
        
        bytes memory tmp = bytes(str);
        bytes memory ret = new bytes(tmp.length);

        for(uint i=0; i<tmp.length; i++){
            ret[i] = tmp[tmp.length-i-1];
        }

        return string(ret);
    }
}