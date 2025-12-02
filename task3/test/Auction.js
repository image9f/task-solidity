import { expect } from "chai";
import pkg from "hardhat";
const { ethers, upgrades } = pkg;

describe("AuctionUpgradeable", function () {
  let AuctionUpgradeable;
  let auction;
  let MyNFT;
  let myNFT;
  let owner;
  let addr1;
  let addr2;
  let ethUsdPriceFeedMock;
  let erc20UsdPriceFeedMock;
  let MockERC20;
  let mockERC20;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy MyNFT
    MyNFT = await ethers.getContractFactory("MyNFT");
    myNFT = await MyNFT.deploy();
    await myNFT.waitForDeployment();

    // Deploy MockERC20
    MockERC20 = await ethers.getContractFactory("MockERC20");
    mockERC20 = await MockERC20.deploy();
    await mockERC20.waitForDeployment();

    // Deploy Mock Price Feeds
    const AggregatorV3Interface = await ethers.getContractFactory("MockV3Aggregator");
    ethUsdPriceFeedMock = await AggregatorV3Interface.deploy(8, 200000000000); // 2000 USD per ETH
    erc20UsdPriceFeedMock = await AggregatorV3Interface.deploy(8, 100000000); // 1 USD per ERC20

    // Deploy AuctionUpgradeable
    AuctionUpgradeable = await ethers.getContractFactory("AuctionUpgradeable");
    auction = await upgrades.deployProxy(AuctionUpgradeable, [owner.address], { kind: "uups" });
    await auction.waitForDeployment();

    // Set price feeds
    await auction.setEthUsdPriceFeed(ethUsdPriceFeedMock.target);
    await auction.setPriceFeed(mockERC20.target, erc20UsdPriceFeedMock.target);
  });

  describe("Deployment and Initialization", function () {
    it("Should set the correct owner", async function () {
      expect(await auction.owner()).to.equal(owner.address);
    });

    it("Should have price feeds set", async function () {
      expect(await auction.ethUsdPriceFeed()).to.equal(ethUsdPriceFeedMock.target);
      expect(await auction.priceFeeds(mockERC20.target)).to.equal(erc20UsdPriceFeedMock.target);
    });
  });

  describe("Auction Creation", function () {
    it("Should create an auction with ETH as start price", async function () {
      await myNFT.safeMint(owner.address);
      await myNFT.approve(auction.target, 0);

      const tx = await auction.createAuction(myNFT.target, 0, ethers.parseEther("1"), 0, ethers.ZeroAddress, 3600);
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => auction.interface.parseLog(log)?.name === "AuctionCreated");
      const [auctionId, seller, nftContract, tokenId, startPrice, endTimestamp] = event.args;

      expect(auctionId).to.equal(1);
      expect(seller).to.equal(owner.address);
      expect(nftContract).to.equal(myNFT.target);
      expect(tokenId).to.equal(0);
      expect(startPrice).to.equal(ethers.parseEther("1"));
      expect(endTimestamp).to.be.closeTo((await ethers.provider.getBlock(receipt.blockNumber)).timestamp + 3600, 1);

      const createdAuction = await auction.auctions(1);
      expect(createdAuction.seller).to.equal(owner.address);
      expect(createdAuction.nftContract).to.equal(myNFT.target);
      expect(createdAuction.tokenId).to.equal(0);
      expect(createdAuction.startPrice).to.equal(ethers.parseEther("1"));
      expect(createdAuction.highestBidCurrency).to.equal(0);
      expect(createdAuction.highestBidInUsd).to.equal(ethers.parseUnits("2000", 18)); // 1 ETH * 2000 USD/ETH
    });

    it("Should create an auction with ERC20 as start price", async function () {
      await myNFT.safeMint(owner.address);
      await myNFT.approve(auction.target, 0);
      await mockERC20.mint(owner.address, ethers.parseEther("100"));

      const tx2 = await auction.createAuction(myNFT.target, 0, ethers.parseEther("10"), 1, mockERC20.target, 3600);
      const receipt2 = await tx2.wait();
      const event2 = receipt2.logs.find(log => auction.interface.parseLog(log)?.name === "AuctionCreated");
      const [auctionId2, seller2, nftContract2, tokenId2, startPrice2, endTimestamp2] = event2.args;

      expect(auctionId2).to.equal(1);
      expect(seller2).to.equal(owner.address);
      expect(nftContract2).to.equal(myNFT.target);
      expect(tokenId2).to.equal(0);
      expect(startPrice2).to.equal(ethers.parseEther("10"));
      expect(endTimestamp2).to.be.closeTo((await ethers.provider.getBlock(receipt2.blockNumber)).timestamp + 3600, 1);

      const createdAuction = await auction.auctions(1);
      expect(createdAuction.seller).to.equal(owner.address);
      expect(createdAuction.nftContract).to.equal(myNFT.target);
      expect(createdAuction.tokenId).to.equal(0);
      expect(createdAuction.startPrice).to.equal(ethers.parseEther("10"));
      expect(createdAuction.highestBidCurrency).to.equal(1);
      expect(createdAuction.erc20TokenAddress).to.equal(mockERC20.target);
      expect(createdAuction.highestBidInUsd).to.equal(ethers.parseUnits("10", 18)); // 10 ERC20 * 1 USD/ERC20
    });
  });

  describe("Bidding", function () {
    beforeEach(async function () {
      await myNFT.safeMint(owner.address);
      await myNFT.approve(auction.target, 0);
      const tx = await auction.createAuction(myNFT.target, 0, ethers.parseEther("1"), 0, ethers.ZeroAddress, 3600);
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => auction.interface.parseLog(log)?.name === "AuctionCreated");
      const [auctionId, seller, nftContract, tokenId, startPrice, endTimestamp] = event.args;

      expect(auctionId).to.equal(1);
      expect(seller).to.equal(owner.address);
      expect(nftContract).to.equal(myNFT.target);
      expect(tokenId).to.equal(0);
      expect(startPrice).to.equal(ethers.parseEther("1"));
      expect(endTimestamp).to.be.closeTo((await ethers.provider.getBlock(receipt.blockNumber)).timestamp + 3600, 1);
    });

    it("Should allow ETH bid", async function () {
      await expect(auction.connect(addr1).placeBid(1, { value: ethers.parseEther("1.1") }))
        .to.emit(auction, "BidPlaced")
        .withArgs(1, addr1.address, ethers.parseEther("1.1"));

      const updatedAuction = await auction.auctions(1);
      expect(updatedAuction.highestBidder).to.equal(addr1.address);
      expect(updatedAuction.highestBid).to.equal(ethers.parseEther("1.1"));
      expect(updatedAuction.highestBidCurrency).to.equal(0);
      expect(updatedAuction.highestBidInUsd).to.equal(ethers.parseUnits("2200", 18)); // 1.1 ETH * 2000 USD/ETH
    });

    it("Should allow ERC20 bid", async function () {
      await mockERC20.mint(addr2.address, ethers.parseEther("2500"));
      await mockERC20.connect(addr2).approve(auction.target, ethers.parseEther("2500"));

      await expect(auction.connect(addr2).placeBidERC20(1, ethers.parseEther("2500"), mockERC20.target))
        .to.emit(auction, "BidPlaced")
        .withArgs(1, addr2.address, ethers.parseEther("2500"));

      const updatedAuction = await auction.auctions(1);
      expect(updatedAuction.highestBidder).to.equal(addr2.address);
      expect(updatedAuction.highestBid).to.equal(ethers.parseEther("2500"));
      expect(updatedAuction.highestBidCurrency).to.equal(1);
      expect(updatedAuction.erc20TokenAddress).to.equal(mockERC20.target);
      expect(updatedAuction.highestBidInUsd).to.equal(ethers.parseUnits("2500", 18)); // 2500 ERC20 * 1 USD/ERC20
    });

    it("Should not allow bid lower than current highest bid in USD", async function () {
      await auction.connect(addr1).placeBid(1, { value: ethers.parseEther("1.1") });

      await expect(auction.connect(addr2).placeBid(1, { value: ethers.parseEther("1.05") }))
        .to.be.revertedWith("Bid must be higher than current highest bid in USD");
    });

    it("Should refund previous bidder", async function () {
      await auction.connect(addr1).placeBid(1, { value: ethers.parseEther("1.1") });
      const addr1BalanceBefore = await ethers.provider.getBalance(addr1.address);

      await auction.connect(addr2).placeBid(1, { value: ethers.parseEther("1.2") });
      const addr1BalanceAfter = await ethers.provider.getBalance(addr1.address);

      // Expect addr1 to be refunded (approximately, due to gas costs)
      expect(addr1BalanceAfter).to.be.closeTo(addr1BalanceBefore + ethers.parseEther("1.1"), ethers.parseEther("0.01"));
    });
  });

  describe("Auction Ending", function () {
    beforeEach(async function () {
      await myNFT.safeMint(owner.address);
      await myNFT.approve(auction.target, 0);
      await auction.createAuction(myNFT.target, 0, ethers.parseEther("1"), 0, ethers.ZeroAddress, 100); // 100 second duration

      await auction.connect(addr1).placeBid(1, { value: ethers.parseEther("1.1") });

      // Mine a block to advance time for auction to end
      await ethers.provider.send("evm_increaseTime", [101]);
      await ethers.provider.send("evm_mine");
    });

    it("Should end auction and transfer NFT and funds", async function () {
      const ownerBalanceBefore = await ethers.provider.getBalance(owner.address);
      const addr1BalanceBefore = await ethers.provider.getBalance(addr1.address);

      await expect(auction.endAuction(1))
        .to.emit(auction, "AuctionEnded")
        .withArgs(1, addr1.address, ethers.parseEther("1.1"));

      // NFT should be transferred to the highest bidder
      expect(await myNFT.ownerOf(0)).to.equal(addr1.address);

      // Funds should be transferred to the seller
      expect(await ethers.provider.getBalance(owner.address)).to.be.closeTo(ownerBalanceBefore + ethers.parseEther("1.1"), ethers.parseEther("0.01"));
    });

    it("Should return NFT to seller if no bids", async function () {
      await myNFT.safeMint(owner.address);
      await myNFT.approve(auction.target, 1);
      await auction.createAuction(myNFT.target, 1, ethers.parseEther("1"), 0, ethers.ZeroAddress, 1); // 1 second duration

      // Mine a block to advance time
      await ethers.provider.send("evm_increaseTime", [2]);
      await ethers.provider.send("evm_mine");

      await expect(auction.endAuction(2))
        .to.emit(auction, "AuctionEnded")
        .withArgs(2, ethers.ZeroAddress, ethers.parseEther("1"));

      // NFT should be returned to the seller
      expect(await myNFT.ownerOf(1)).to.equal(owner.address);
    });
  });

  describe("Upgradeability", function () {
    it("Should be able to upgrade the contract", async function () {
      const AuctionV2 = await ethers.getContractFactory("AuctionUpgradeable"); // Assuming AuctionUpgradeable is V1 and V2 for simplicity
      const upgradedAuction = await upgrades.upgradeProxy(auction.target, AuctionV2);

      expect(upgradedAuction.target).to.equal(auction.target);
    });
  });
});

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