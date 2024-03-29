import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import tokenJSON from "../artifacts/contracts/SolarGreen.sol/SolarGreen.json";

describe("TokenSale", function () {
  async function deploy() {
    const [owner, buyer, spender] = await ethers.getSigners();

    const TokenSale = await ethers.getContractFactory("TokenSale", owner);
    const shop = await TokenSale.deploy();

    const erc20 = new ethers.Contract(await shop.token(), tokenJSON.abi, owner);

    return { owner, buyer, spender, shop, erc20 };
  }

  it("should have an owner", async function () {
    const { owner, shop } = await loadFixture(deploy);

    expect(await shop.owner()).to.eq(owner.address);
    expect(await shop.getAddress()).to.be.properAddress;
  });

  it("allow to buy", async function () {
    const { buyer, shop, erc20 } = await loadFixture(deploy);

    const tokenAmount = 3;

    const txData = {
      value: tokenAmount,
      to: shop.target,
    };

    const tx = await buyer.sendTransaction(txData);
    await tx.wait();

    expect(await erc20.balanceOf(buyer.address)).to.eq(tokenAmount);
    expect(() => tx).to.changeEtherBalance(shop, tokenAmount);
    expect(tx).to.emit(shop, "Bought").withArgs(tokenAmount, buyer.address);
  });

  it("can't buy more than 50k token", async function () {
    const { buyer, shop } = await loadFixture(deploy);
    const tokenAmount = 30000;

    const txData = {
      value: tokenAmount,
      to: shop.target,
    };

    const tx = await buyer.sendTransaction(txData);
    await tx.wait();

    await expect(buyer.sendTransaction(txData)).to.be.revertedWith("can't buy more than 50k token");
  });

  it("can't buy less than 1 token", async function () {
    const { buyer, shop } = await loadFixture(deploy);
    const tokenAmount = 0;

    const txData = {
      value: tokenAmount,
      to: shop.target,
    };

    await expect(buyer.sendTransaction(txData)).to.be.revertedWith("not enough funds!");
  });

  it("change end time of sale", async function () {
    const { shop } = await loadFixture(deploy);

    const duration = 1000;

    const expectedSaleEndTime = (await shop.startAt()) + BigInt(1000);

    await shop.setSaleEndTime(duration);

    expect(await shop.endsAt()).to.eq(expectedSaleEndTime);
  });

  it("can't buy token after end of token sale", async function () {
    const { buyer, shop } = await loadFixture(deploy);
    const tokenAmount = 5;

    const txData = {
      value: tokenAmount,
      to: shop.target,
    };

    await shop.setSaleEndTime(0);

    await expect(buyer.sendTransaction(txData)).to.be.revertedWith("sale has ended");
  });

  it("can't buy token before start of token sale", async function () {
    const { buyer, shop } = await loadFixture(deploy);
    const tokenAmount = 5;

    const txData = {
      value: tokenAmount,
      to: shop.target,
    };

    const futureSaleStartTime = (await shop.startAt()) + BigInt(1000);

    await shop.setSaleStartTime(futureSaleStartTime);

    await expect(buyer.sendTransaction(txData)).to.be.revertedWith("sale has not started yet");
  });
});
