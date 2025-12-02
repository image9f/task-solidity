import { expect } from "chai";
import pkg from "hardhat";
const { ethers } = pkg;

describe("MyNFT", function () {
  let MyNFT;
  let myNFT;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    MyNFT = await ethers.getContractFactory("MyNFT");
    [owner, addr1, addr2] = await ethers.getSigners();
    myNFT = await MyNFT.deploy();
    await myNFT.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await myNFT.owner()).to.equal(owner.address);
    });

    it("Should have the correct name and symbol", async function () {
      expect(await myNFT.name()).to.equal("MyNFT");
      expect(await myNFT.symbol()).to.equal("MNFT");
    });
  });

  describe("Minting", function () {
    it("Should mint a new NFT", async function () {
      await myNFT.safeMint(addr1.address);
      expect(await myNFT.ownerOf(0)).to.equal(addr1.address);
      expect(await myNFT.balanceOf(addr1.address)).to.equal(1);
    });

    it("Should not allow non-owner to mint", async function () {
      await expect(myNFT.connect(addr1).safeMint(addr1.address)).to.be.revertedWithCustomError(myNFT, "OwnableUnauthorizedAccount");
    });
  });

  describe("Transfer", function () {
    beforeEach(async function () {
      await myNFT.safeMint(owner.address);
    });

    it("Should allow owner to transfer NFT", async function () {
      await myNFT.transferFrom(owner.address, addr1.address, 0);
      expect(await myNFT.ownerOf(0)).to.equal(addr1.address);
      expect(await myNFT.balanceOf(owner.address)).to.equal(0);
      expect(await myNFT.balanceOf(addr1.address)).to.equal(1);
    });

    it("Should not allow non-owner to transfer NFT", async function () {
      await expect(myNFT.connect(addr1).transferFrom(owner.address, addr2.address, 0)).to.be.revertedWithCustomError(myNFT, "ERC721InsufficientApproval");
    });
  });
});