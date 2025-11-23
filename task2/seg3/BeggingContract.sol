// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BeggingContract {
    address public owner;
    mapping(address => uint256) public donations;

    address[] private donors;
    mapping(address => bool) private isDonor;

    uint256 public donationStart;
    uint256 public donationEnd;

    event Donation(address indexed donor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setDonationWindow(uint256 start, uint256 end) external onlyOwner {
        require(end == 0 || end > start, "Invalid window");
        donationStart = start;
        donationEnd = end;
    }

    function donate() external payable {
        require(msg.value > 0, "No ether");
        if (donationStart != 0) {
            require(block.timestamp >= donationStart, "Too early");
        }
        if (donationEnd != 0) {
            require(block.timestamp <= donationEnd, "Too late");
        }
        donations[msg.sender] += msg.value;
        if (!isDonor[msg.sender]) {
            isDonor[msg.sender] = true;
            donors.push(msg.sender);
        }
        emit Donation(msg.sender, msg.value);
    }

    receive() external payable {
        donations[msg.sender] += msg.value;
        if (!isDonor[msg.sender]) {
            isDonor[msg.sender] = true;
            donors.push(msg.sender);
        }
        emit Donation(msg.sender, msg.value);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Empty");
        payable(owner).transfer(amount);
    }

    function getDonation(address donor) external view returns (uint256) {
        return donations[donor];
    }

    function getTopDonors() external view returns (address[3] memory addrs, uint256[3] memory amounts) {
        address[3] memory topAddrs;
        uint256[3] memory topAmounts;
        uint256 len = donors.length;
        for (uint256 i = 0; i < len; i++) {
            address d = donors[i];
            uint256 a = donations[d];
            if (a > topAmounts[0]) {
                topAmounts[2] = topAmounts[1];
                topAddrs[2] = topAddrs[1];
                topAmounts[1] = topAmounts[0];
                topAddrs[1] = topAddrs[0];
                topAmounts[0] = a;
                topAddrs[0] = d;
            } else if (a > topAmounts[1]) {
                topAmounts[2] = topAmounts[1];
                topAddrs[2] = topAddrs[1];
                topAmounts[1] = a;
                topAddrs[1] = d;
            } else if (a > topAmounts[2]) {
                topAmounts[2] = a;
                topAddrs[2] = d;
            }
        }
        return (topAddrs, topAmounts);
    }
}

