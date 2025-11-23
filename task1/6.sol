// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract BinSearch{


    function bin_serach(uint8[] memory arr, uint8 val) public pure returns(uint){

        uint i = 0;
        uint j = uint(arr.length)-1;
        uint m;

        while(i <= j){
            m = i + (j-i)/2;
            
            if(arr[m] < val){
                i = m + 1;
            }else if(arr[m] > val){
                j = m - 1;
            }else {
                return m;
            }
        }
        revert("val not found");
    }
}