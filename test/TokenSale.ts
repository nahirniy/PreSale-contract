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

    const precision = ethers.parseUnits("10", 18);
    const availableTokens = ethers.parseUnits("50000000", 18);
    const limitTokensPerUser = ethers.parseUnits("50000", 18);
    const tokenPrice = ethers.parseUnits("7", 18) / BigInt(100); // 0.07$ per token
    const vestingEnd = 1735696799;

    const mockV3AggregatorFactory = await ethers.getContractFactory("MockV3Aggregator");
    const mockV3Aggregator = await mockV3AggregatorFactory.deploy(DECIMALS, INITIAL_PRICE);

    const Tether = await ethers.getContractFactory("TestUSTD");
    const usdt = await Tether.deploy();

    const TokenSale = await ethers.getContractFactory("TokenSale", owner);
    const shop = await TokenSale.deploy(
      owner,
      usdt.target,
      precision,
      availableTokens,
      limitTokensPerUser,
      tokenPrice,
      vestingEnd,
      mockV3Aggregator.target
    );

    const token = new ethers.Contract(await shop.token(), tokenJSON.abi, owner);

    return { owner, buyer, spender, shop, token, usdt };
  }

  it("should have an owner", async function () {
    const { owner, shop } = await loadFixture(deploy);

    expect(await shop.owner()).to.eq(owner.address);
    expect(await shop.getAddress()).to.be.properAddress;
  });

  it("allow to buy for Eth", async function () {
    const { buyer, shop } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("100", 18);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);

    const txData = { value: ethAmount };

    const tx = await shop.connect(buyer).buyWithEth(tokenAmount, txData);
    tx.wait();

    expect(tx).to.emit(shop, "Bought").withArgs(tokenAmount, buyer.address);
    expect(() => tx).to.changeEtherBalance(shop, tokenAmount);
    expect(await shop.checkUserBalance(buyer.address)).to.eq(tokenAmount);
  });

  it("allow to buy for USTD", async function () {
    const { buyer, spender, shop, token, usdt } = await loadFixture(deploy);

    const tokenAmount = BigInt(100) * (await shop.BASE_MULTIPLIER());
    const usdtAmount = await shop.usdtBuyHelper(tokenAmount);

    await usdt.connect(buyer).mint();
    await usdt.connect(buyer).approve(shop.target, usdtAmount);

    const tx = await shop.connect(buyer).buyWithUSDT(tokenAmount);
    tx.wait();

    expect(tx).to.emit(shop, "Bought").withArgs(tokenAmount, buyer.address);
    expect(await shop.checkUserBalance(buyer.address)).to.eq(tokenAmount);
    expect(await usdt.balanceOf(shop.target)).to.equal(usdtAmount);
  });

  it("can't buy more than 50k token", async function () {
    const { buyer, shop } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("30000", 18);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);

    const txData = { value: ethAmount };

    const tx = await shop.connect(buyer).buyWithEth(tokenAmount, txData);
    tx.wait();

    await expect(shop.connect(buyer).buyWithEth(tokenAmount, txData)).to.be.revertedWith(
      "cant buy more than 50k"
    );
  });

  it("can't buy less than 1 token", async function () {
    const { buyer, shop } = await loadFixture(deploy);
    const tokenAmount = ethers.parseUnits("0", 18);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);

    const txData = { value: ethAmount };

    await expect(shop.connect(buyer).buyWithEth(tokenAmount, txData)).to.be.revertedWith("not enough funds!");
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

    const tokenAmount = ethers.parseUnits("30000", 18);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);

    const txData = { value: ethAmount };

    await shop.setSaleEndTime(0);

    await expect(shop.connect(buyer).buyWithEth(tokenAmount, txData)).to.be.revertedWith("sale has ended");
  });
});
