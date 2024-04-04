import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();

  const owner = "0xF495a8a96A5E933Ce3CD0ee89BD02550232e5A49";
  const usdt = "0x1531BC5dE10618c511349f8007C08966E45Ce8ef";
  const tokenPrice = BigInt((7 * 10 ** 18) / 100); // 0.07$ per token
  const priceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

  const TokenSale = await ethers.getContractFactory("TokenSale", signer);
  const shop = await TokenSale.deploy(owner, usdt, priceFeed, tokenPrice);
  shop.waitForDeployment();

  console.log(shop.target);

  console.log(await shop.token());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
