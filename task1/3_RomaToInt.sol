// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract TransRoma{


    function trans(uint8 xx) internal pure returns (uint){
        uint ret = 0;

        if(xx == uint8(bytes1('I'))) 
            ret = 1;
        else if(xx == uint8(bytes1('V'))) 
            ret = 5;
        else if(xx == uint8(bytes1('X'))) 
            ret = 10;
        else if(xx == uint8(bytes1('L'))) 
            ret = 50;
        else if(xx == uint8(bytes1('C'))) 
            ret = 100;
        else if(xx == uint8(bytes1('D'))) 
            ret = 500;
        else if(xx == uint8(bytes1('M'))) 
            ret = 1000;

        return ret;
    }


    function tranasroma(string memory input) public pure returns(uint){
        bytes memory val = bytes(input);
        uint ret = 0;
        uint tmp;
        uint tmp2 = 0;

        for(uint i=val.length; i > 0; i--){
            tmp = trans(uint8(val[i-1]));
            if(tmp < tmp2)
                ret -= tmp;
            else
                ret += tmp;
            
            tmp2 = tmp;
        }

        return ret;
    }
}
