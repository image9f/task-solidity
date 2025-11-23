// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


contract MergeArr{

    function merge(uint[] memory arr1,uint[] memory arr2) public pure returns(uint[] memory){

        uint len1 = arr1.length;
        uint len2 = arr2.length;

        uint[] memory arr = new uint[](len1+len2);

        uint x=0;
        uint y=0;
        uint z=0;

        while(x<len1 && y<len2)
        {
            if(arr1[x] < arr2[y]){
                arr[z] = arr1[x];
                x++;
            }else{
                arr[z] = arr2[y];
                y++;
            }
            z++;
        }

        while(x<len1){
            arr[z] = arr1[x];
            x++;
            z++;
        }

        while(y<len2){
            arr[z] = arr2[y];
            y++;
            z++;
        }

        return arr;

    }


}