// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Voting {

    mapping(string => uint16) public votes;

    function vote(string memory candidate) public {
        votes[candidate]++;
    }

    function getVotes(string memory candidate) public view returns (uint16) {
        return votes[candidate];
    }

    function resetVotes(string[] memory candidate) public {
        for (uint16 i = 0; i < candidate.length; i++){
            votes[candidate[i]] = 0;
        }
    }

}
