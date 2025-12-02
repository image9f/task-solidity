// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 我的NFT合约
contract MyNFT is ERC721, Ownable {
    // 内部计数器，用于生成新的tokenId
    uint256 private _tokenIdCounter;

    // 构造函数，初始化ERC721代币名称和符号，并设置合约所有者
    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    // 安全铸造NFT，只有合约所有者才能调用
    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter; // 获取当前tokenId
        _tokenIdCounter++; // tokenId自增
        _safeMint(to, tokenId); // 安全铸造NFT到指定地址
    }

    // 以下函数是Solidity要求的重写函数。

    // 支持接口查询
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}