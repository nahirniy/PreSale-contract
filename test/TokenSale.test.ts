import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("TokenSale", function () {
  async function deploy() {
    const [owner, buyer, spender] = await ethers.getSigners();

    const DECIMALS = "18";
    const INITIAL_PRICE = "360000000000"; // 3600$ ETH/USDT
    const tokenPrice = ethers.parseUnits("7", 16); // 0.07$ per token
    const tokensForPurchase = ethers.parseUnits("50000000", 18);

    const mockV3AggregatorFactory = await ethers.getContractFactory("MockV3Aggregator");
    const mockV3Aggregator = await mockV3AggregatorFactory.deploy(DECIMALS, INITIAL_PRICE);
    mockV3Aggregator.waitForDeployment();

    const Tether = await ethers.getContractFactory("TestUSTD");
    const usdt = await Tether.deploy();
    usdt.waitForDeployment();

    const SolarGreen = await ethers.getContractFactory("SolarGreen", owner);
    const token = await SolarGreen.deploy(owner.address, owner.address);
    token.waitForDeployment();

    const TokenSale = await ethers.getContractFactory("TokenSale", owner);
    const shop = await TokenSale.deploy(
      owner,
      usdt.target,
      mockV3Aggregator.target,
      token.target,
      tokenPrice
    );
    shop.waitForDeployment();

    await token.mint(shop.target, tokensForPurchase);

    return { owner, buyer, spender, shop, token, usdt };
  }

  it("should have an owner", async function () {
    const { owner, shop } = await loadFixture(deploy);

    expect(await shop.owner()).to.eq(owner.address);
    expect(await shop.getAddress()).to.be.properAddress;
  });

  it("correct work function that canculate eth and usdt amount for token", async function () {
    const { buyer, shop } = await loadFixture(deploy);

    const tokenPrice = ethers.parseUnits("7", 16); // 0.07$ per token
    const precision = ethers.parseUnits("1", 18);
    const tokenAmount = ethers.parseUnits("700", 18);
    const ethPrice = await shop.getLatestPrice();

    const usdtAmount = (tokenAmount * tokenPrice) / precision;
    const ethAmount = (usdtAmount * precision) / ethPrice;

    expect(await shop.usdtBuyHelper(tokenAmount)).to.eq(usdtAmount);
    expect(await shop.ethBuyHelper(tokenAmount)).to.eq(ethAmount);
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
    const { buyer, shop, usdt } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("100", 18);
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

    await expect(shop.connect(buyer).buyWithEth(tokenAmount, txData)).to.be.revertedWith(
      "sale is not active"
    );
  });

  it("can't buy token if address in blacklist", async function () {
    const { buyer, shop, token } = await loadFixture(deploy);

    await token.addToBlacklist(buyer.address);

    const tokenAmount = ethers.parseUnits("100", 18);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);

    const txData = { value: ethAmount };

    expect(await token.isBlacklisted(buyer.address)).to.eq(true);
    await expect(shop.connect(buyer).buyWithEth(tokenAmount, txData)).to.be.revertedWith(
      "recipiant is blacklisted"
    );
  });

  it("correct work of ustd, token, and ether balances", async function () {
    const { buyer, shop, usdt, token } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("100", 18);
    const usdtAmount = await shop.usdtBuyHelper(tokenAmount);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);
    const sumTokenAmount = tokenAmount + tokenAmount;

    const txData = { value: ethAmount };

    await usdt.connect(buyer).mint();
    await usdt.connect(buyer).approve(shop.target, usdtAmount);
    await shop.connect(buyer).buyWithUSDT(tokenAmount);
    await shop.connect(buyer).buyWithEth(tokenAmount, txData);

    expect(await shop.checkUserBalance(buyer.address)).to.eq(sumTokenAmount);
    expect(await shop.ethBalance()).to.eq(ethAmount);
    expect(await shop.usdtBalance()).to.eq(usdtAmount);
    expect(await token.balanceOf(shop.target)).to.eq(await shop.tokenBalance()); // since token in the vesting
  });

  it("correct update token price", async function () {
    const { buyer, shop, usdt } = await loadFixture(deploy);

    const newPrice = ethers.parseUnits("1", 18); // 1$
    await shop.updateTokenPrice(newPrice);
    const tokenAmount = ethers.parseUnits("100", 18);
    const usdtAmount = await shop.usdtBuyHelper(tokenAmount);

    await usdt.connect(buyer).mint();
    await usdt.connect(buyer).approve(shop.target, usdtAmount);
    await shop.connect(buyer).buyWithUSDT(tokenAmount);

    expect(await shop.checkUserBalance(buyer.address)).to.eq(tokenAmount);
    expect(await shop.usdtBalance()).to.eq(usdtAmount);
  });

  it("can claim token after vesting period", async function () {
    const { buyer, shop, usdt, token } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("100", 18);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);
    const txData = { value: ethAmount };

    const txBuy = await shop.connect(buyer).buyWithEth(tokenAmount, txData);
    txBuy.wait();

    const timeAfterVesting = Number(await shop.vestingEnd()) + 1000;
    await ethers.provider.send("evm_setNextBlockTimestamp", [timeAfterVesting]);
    await ethers.provider.send("evm_mine");

    const txClaim = await shop.claimToken(buyer.address);
    txClaim.wait();

    expect(() => txBuy).to.changeEtherBalance(shop, tokenAmount);
    expect(await shop.checkUserBalance(buyer.address)).to.eq(0);
    expect(await shop.ethBalance()).to.eq(ethAmount);
    expect(await token.balanceOf(buyer.address)).to.eq(tokenAmount);
    expect(await token.balanceOf(shop.target)).to.eq(await shop.availableTokens());
    expect(txClaim).to.emit(shop, "Claimed").withArgs(tokenAmount, buyer.address);
  });

  it("cant claim token during vesting period", async function () {
    const { buyer, shop } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("100", 18);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);
    const txData = { value: ethAmount };

    await shop.connect(buyer).buyWithEth(tokenAmount, txData);

    await expect(shop.claimToken(buyer.address)).to.be.revertedWith(
      "token claim will be allowed after 2024-12-31"
    );
  });

  it("only owner can withdraw ether from contract", async function () {
    const { owner, buyer, shop } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("100", 18);
    const ethAmount = await shop.ethBuyHelper(tokenAmount);
    const txData = { value: ethAmount };

    const txBuy = await shop.connect(buyer).buyWithEth(tokenAmount, txData);
    txBuy.wait();

    const beforeBalance = await ethers.provider.getBalance(owner.address);

    const txWithdraw = await shop.connect(owner).withdrawETH(ethAmount);
    txWithdraw.wait();

    const afterBalance = await ethers.provider.getBalance(owner.address);

    expect(await shop.ethBalance()).to.eq(0);
    expect(beforeBalance).to.be.at.most(afterBalance);
    await expect(shop.connect(owner).withdrawETH("1")).to.be.revertedWith("insufficient ETH balance");

    await shop.connect(buyer).buyWithEth(tokenAmount, txData);
    await expect(shop.connect(buyer).withdrawETH(ethAmount)).to.be.reverted;
  });

  it("only owner can withdraw usdt from contract", async function () {
    const { owner, buyer, shop, usdt } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("100", 18);
    const usdtAmount = await shop.usdtBuyHelper(tokenAmount);

    await usdt.connect(buyer).mint();
    await usdt.connect(buyer).approve(shop.target, usdtAmount * BigInt(2));

    const txBuy = await shop.connect(buyer).buyWithUSDT(tokenAmount);
    txBuy.wait();

    const beforeBalance = await usdt.balanceOf(owner.address);

    const txWithdraw = await shop.connect(owner).withdrawUSDT(usdtAmount);
    txWithdraw.wait();

    const afterBalance = await usdt.balanceOf(owner.address);

    expect(await shop.usdtBalance()).to.eq(0);
    expect(beforeBalance).to.be.at.most(afterBalance);
    await expect(shop.connect(owner).withdrawUSDT("1")).to.be.revertedWith("insufficient USDT balance");

    await shop.connect(buyer).buyWithUSDT(tokenAmount);
    await expect(shop.connect(buyer).withdrawUSDT(usdtAmount)).to.be.reverted;
  });

  it("only owner can withdraw token from contract", async function () {
    const { owner, buyer, shop, token } = await loadFixture(deploy);

    const tokenAmount = ethers.parseUnits("100", 18);
    const availableTokens = ethers.parseUnits("50000000", 18);

    const beforeBalance = await shop.tokenBalance();
    const beforeOwnerBalance = await token.balanceOf(owner.address);

    const txWithdraw = await shop.connect(owner).withdrawToken(tokenAmount);
    txWithdraw.wait();

    const afterBalance = await shop.tokenBalance();
    const afterOwnerBalance = await token.balanceOf(owner.address);

    expect(afterBalance).to.eq(beforeBalance - tokenAmount);
    expect(afterOwnerBalance).to.eq(beforeOwnerBalance + tokenAmount);

    await expect(shop.withdrawToken(availableTokens)).to.be.revertedWith("insufficient token balance");
    await expect(shop.connect(buyer).withdrawToken("1")).to.be.reverted;
  });
});
