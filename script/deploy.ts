import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();

  const SolarGreen = await ethers.getContractFactory("SolarGreen", signer);
  const token = await SolarGreen.deploy(signer.address);

  console.log("Token deployed to address:", token.target);

  const TokenSale = await ethers.getContractFactory("TokenSale", signer);
  const shop = await TokenSale.deploy();

  console.log(shop.target);
  //   console.log(await shop.token());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
