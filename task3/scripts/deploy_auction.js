import { ethers, upgrades } from "hardhat";

async function main() {
  const Auction = await ethers.getContractFactory("AuctionUpgradeable");
  const auction = await upgrades.deployProxy(Auction, [/* constructor arguments for initialize */], {
    kind: "uups",
  });

  await auction.waitForDeployment();

  console.log("Auction deployed to:", await auction.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});