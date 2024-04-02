import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import tokenJSON from "../artifacts/contracts/SolarGreen.sol/SolarGreen.json";
import usdtJSON from "../artifacts/contracts/test/TestUSTD.sol/TestUSTD.json";

// beforeEach
describe("TokenSale", function () {
  async function deploy() {
    const [owner, buyer, spender] = await ethers.getSigners();

    const DECIMALS = "18";
    const INITIAL_PRICE = "360000000000";

    const ustd = "0x1531BC5dE10618c511349f8007C08966E45Ce8ef";
    const precision = BigInt(10 ** 18);
    const availableTokens = BigInt(50000000) * precision;
    const limitTokensPerUser = BigInt(50000) * precision;
    const tokenPrice = (BigInt(7) * precision) / BigInt(100); // 0.07$ per token
    const vestingEnd = 1735696799;

    const mockV3AggregatorFactory = await ethers.getContractFactory("MockV3Aggregator");
    const mockV3Aggregator = await mockV3AggregatorFactory.deploy(DECIMALS, INITIAL_PRICE);

    const Tether = await ethers.getContractFactory("TestUSTD");
    const stablecoin = await Tether.deploy();

    const TokenSale = await ethers.getContractFactory("TokenSale", owner);
    const shop = await TokenSale.deploy(
      owner,
      stablecoin.target,
      precision,
      availableTokens,
      limitTokensPerUser,
      tokenPrice,
      vestingEnd,
      mockV3Aggregator.target
    );

    const token = new ethers.Contract(await shop.token(), tokenJSON.abi, owner);
    const usdt = new ethers.Contract(await shop.usdt(), usdtJSON.abi, owner);

    return { owner, buyer, spender, shop, token, usdt, stablecoin };
  }

  it("should have an owner", async function () {
    const { owner, shop } = await loadFixture(deploy);

    expect(await shop.owner()).to.eq(owner.address);
    expect(await shop.getAddress()).to.be.properAddress;
  });

  it("allow to buy for Eth", async function () {
    const { buyer, shop } = await loadFixture(deploy);

    const tokenAmount = BigInt(100) * (await shop.BASE_MULTIPLIER());
    const ethAmount = await shop.ethBuyHelper(tokenAmount);

    const txData = { value: ethAmount };

    const tx = await shop.connect(buyer).buyWithEth(tokenAmount, txData);
    tx.wait();

    expect(tx).to.emit(shop, "Bought").withArgs(tokenAmount, buyer.address);
    expect(() => tx).to.changeEtherBalance(shop, tokenAmount);
    expect(await shop.checkUserBalance(buyer.address)).to.eq(tokenAmount);
  });

  it("allow to for USTD", async function () {
    const { buyer, shop, token, stablecoin } = await loadFixture(deploy);

    const tokenAmount = BigInt(100) * (await shop.BASE_MULTIPLIER());
    const usdtAmount = await shop.usdtBuyHelper(tokenAmount);

    await stablecoin.connect(buyer).mint();

    console.log(await stablecoin.balanceOf(buyer.address));

    await stablecoin.approve(shop.target, usdtAmount);

    console.log(await shop.getAllowance());

    const tx = await shop.connect(buyer).buyWithUSDT(tokenAmount);
    // tx.wait();

    // console.log(tx);

    // console.log(await usdt.balanceOf(buyer.address));
    // console.log(await usdt.balanceOf(shop.target));

    // expect(tx).to.emit(shop, "Bought").withArgs(tokenAmount, buyer.address);
    // expect(() => tx).to.changeEtherBalance(shop, tokenAmount);
    // expect(await shop.checkUserBalance(buyer.address)).to.eq(tokenAmount);
  });

  //   it("can't buy more than 50k token", async function () {
  //     const { buyer, shop } = await loadFixture(deploy);
  //     const tokenAmount = 30000;

  //     const txData = {
  //       value: tokenAmount,
  //       to: shop.target,
  //     };

  //     const tx = await buyer.sendTransaction(txData);
  //     await tx.wait();

  //     await expect(buyer.sendTransaction(txData)).to.be.revertedWith("can't buy more than 50k token");
  //   });

  //   it("can't buy less than 1 token", async function () {
  //     const { buyer, shop } = await loadFixture(deploy);
  //     const tokenAmount = 0;

  //     const txData = {
  //       value: tokenAmount,
  //       to: shop.target,
  //     };

  //     await expect(buyer.sendTransaction(txData)).to.be.revertedWith("not enough funds!");
  //   });

  //   it("change end time of sale", async function () {
  //     const { shop } = await loadFixture(deploy);

  //     const duration = 1000;

  //     const expectedSaleEndTime = (await shop.startAt()) + BigInt(1000);

  //     await shop.setSaleEndTime(duration);

  //     expect(await shop.endsAt()).to.eq(expectedSaleEndTime);
  //   });

  //   it("can't buy token after end of token sale", async function () {
  //     const { buyer, shop } = await loadFixture(deploy);
  //     const tokenAmount = 5;

  //     const txData = {
  //       value: tokenAmount,
  //       to: shop.target,
  //     };

  //     await shop.setSaleEndTime(0);

  //     await expect(buyer.sendTransaction(txData)).to.be.revertedWith("sale has ended");
  //   });

  //   it("can't buy token before start of token sale", async function () {
  //     const { buyer, shop } = await loadFixture(deploy);
  //     const tokenAmount = 5;

  //     const txData = {
  //       value: tokenAmount,
  //       to: shop.target,
  //     };

  //     const futureSaleStartTime = (await shop.startAt()) + BigInt(1000);

  //     await shop.setSaleStartTime(futureSaleStartTime);

  //     await expect(buyer.sendTransaction(txData)).to.be.revertedWith("sale has not started yet");
  //   });
});
