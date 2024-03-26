import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import tokenJSON from "../artifacts/contracts/SolarGreen.sol/SolarGreen.json";

describe("TokenSale", function () {
  async function deploy() {
    const [owner, buyer, spender] = await ethers.getSigners();

    const TokenSale = await ethers.getContractFactory("TokenSale", owner);
    const sale = await TokenSale.deploy();

    const erc20 = new ethers.Contract(await sale.token(), tokenJSON.abi, owner);

    return { owner, buyer, spender, sale, erc20 };
  }

  it("should have an owner", async function () {
    const { owner, sale } = await loadFixture(deploy);

    expect(await sale.owner()).to.eq(owner.address);
    expect(await sale.getAddress()).to.be.properAddress;
  });

  it("allow to buy", async function () {
    const { owner, buyer, sale, erc20 } = await loadFixture(deploy);

    const tokenAmount = 3;

    const txData = {
      value: tokenAmount,
      to: sale.target,
    };

    const tx = await buyer.sendTransaction(txData);
    await tx.wait();

    expect(await erc20.balanceOf(buyer.address)).to.eq(tokenAmount);
    expect(() => tx).to.changeEtherBalance(sale, tokenAmount);
    expect(tx).to.emit(sale, "Bought").withArgs(tokenAmount, buyer.address);
  });
});
