// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract InToRoma{



    function transInt(uint value) public pure returns(string memory){
        require(value >0 && value <= 3999, "Input value error");

        string[] memory roma = new string[](13);
        roma[0] = "M";
        roma[1] = "CM";
        roma[2] = "D";
        roma[3] = "CD";
        roma[4] = "C";
        roma[5] = "XC";
        roma[6] = "L";
        roma[7] = "XL";
        roma[8] = "X";
        roma[9] = "IX";
        roma[10] = "V";
        roma[11] = "IV";
        roma[12] = "I";
        

        uint256[] memory intt = new uint256[](13);
        intt[0] = 1000;
        intt[1] = 900;
        intt[2] = 500;
        intt[3] = 400;
        intt[4] = 100;
        intt[5] = 90;
        intt[6] = 50;
        intt[7] = 40;
        intt[8] = 10;
        intt[9] = 9;
        intt[10] = 5;
        intt[11] = 4;
        intt[12] = 1;


        bytes memory ret = new bytes(0);
        uint tmp = value;

        for(uint i=0;i<13;i++){
            while(tmp >= intt[i]){
                ret = abi.encodePacked(ret,bytes(roma[i]));
                tmp -= intt[i];
            }
        }

        return string(ret);

    }

}
