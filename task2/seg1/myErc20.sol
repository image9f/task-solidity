// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract MyERC20 is IERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    address public owner;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function allowwance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256){
        return balances[account];
    }

    function transfer(address from, address to, uint256 value) public returns (bool){
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balances[msg.sender] > value, "ERC20: tansfer account exceeds balance");

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from,to,value);
        return true;
    }

    function approve(address spender,uint256 value) public returns (bool){
        require(spender != address(0), "ERC20: transfer from the zero address");
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender,spender,value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool){
        require(from != address(0),"ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balances[from] >= value, "ERC20: transfer amount exceeds balance");
        require(allowances[from][msg.sender] >= value, "ERC20: transfer amount exceeds allowance");

        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;
        emit Transfer(from,to,value);

        return true;
    }

    function mint(address account, uint256 value) public onlyOwner returns (bool){
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply += value;
        balances[account] += value;
        emit Transfer(address(0),account, value);
        return true;
    }


   
}   

