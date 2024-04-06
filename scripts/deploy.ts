import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();

  const owner = "0xEbd3C07d5dbef9091Db93BA718cF09a2DAFd4dE2";
  const usdt = "0x1531BC5dE10618c511349f8007C08966E45Ce8ef";
  const priceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";
  const tokenPrice = ethers.parseUnits("7", 16); // 0.07$ per token
  const tokensForPurchase = ethers.parseUnits("50000000", 18); // 50 mln

  const SolarGreen = await ethers.getContractFactory("SolarGreen", signer);
  const token = await SolarGreen.deploy(owner, owner);
  token.waitForDeployment();

  const TokenSale = await ethers.getContractFactory("TokenSale", signer);
  const shop = await TokenSale.deploy(owner, usdt, priceFeed, token.target, tokenPrice);
  shop.waitForDeployment();

  await token.mint(shop.target, tokensForPurchase);
  await shop.startSale();

  console.log("SolarGreen address: ", token.target);
  console.log("TokenSale address: ", shop.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
