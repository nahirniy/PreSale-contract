import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SolarGreen", function () {
  async function deploy() {
    const [owner, buyer, spender, newOwner] = await ethers.getSigners();

    const tokensForPurchase = ethers.parseUnits("50000000", 18);

    const SolarGreen = await ethers.getContractFactory("SolarGreen", owner);
    const token = await SolarGreen.deploy(owner.address, owner.address);

    token.mint(owner.address, tokensForPurchase);

    return { owner, buyer, spender, newOwner, token };
  }

  it("owner must be admin", async function () {
    const { owner, token } = await loadFixture(deploy);

    expect(await token.hasRole(await token.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
    expect(await token.getAddress()).to.be.properAddress;
  });

  it("should be correct supply 100 mln", async function () {
    const { token } = await loadFixture(deploy);

    expect(await token.totalSupply()).to.eq(await token.initiallySupply());
  });

  it("correct transfer to", async function () {
    const { buyer, token } = await loadFixture(deploy);
    const amount = ethers.parseUnits("3", 18);

    await token.transfer(buyer.address, amount);

    const balanceBuyer = await token.balanceOf(buyer.address);
    expect(balanceBuyer).to.equal(amount);
  });

  it("correct transfer from", async function () {
    const { owner, buyer, spender, token } = await loadFixture(deploy);

    const amount = ethers.parseUnits("8", 18);

    await token.approve(spender.address, amount);
    await token.connect(spender).transferFrom(owner.address, buyer.address, amount);

    const balanceBuyer = await token.balanceOf(buyer.address);

    expect(await token.allowance(owner.address, spender.address));
    expect(balanceBuyer).to.eq(amount);
  });

  it("allow to mint new token", async function () {
    const { owner, token } = await loadFixture(deploy);

    const amount = ethers.parseUnits("10", 18);
    const expectedTotalSupply = (await token.totalSupply()) + amount;

    await token.mint(owner.address, amount);

    expect(await token.totalSupply()).to.eq(expectedTotalSupply);
  });

  it("allow to burn token", async function () {
    const { token } = await loadFixture(deploy);

    const amount = ethers.parseUnits("8", 18);
    const expectedTotalSupply = (await token.totalSupply()) - amount;

    await token.burn(amount);

    expect(await token.totalSupply()).to.eq(expectedTotalSupply);
  });

  it("only blacklister should add and remove address to blacklist", async function () {
    const { buyer: blacklister, spender, token } = await loadFixture(deploy);

    await token.addBlacklister(blacklister.address);
    await token.connect(blacklister).addToBlacklist(spender.address);

    expect(await token.isBlacklisted(spender.address)).to.eq(true);

    await token.connect(blacklister).removeFromBlacklist(spender.address);

    expect(await token.isBlacklisted(spender.address)).to.eq(false);
  });

  it("only owner can add and remove a blacklister", async function () {
    const { owner, buyer: blacklister, token } = await loadFixture(deploy);

    await token.addBlacklister(blacklister.address);

    expect(await token.hasRole(await token.BLACKLISTER(), blacklister.address)).to.be.true;

    await token.removeBlacklister(blacklister.address);

    expect(await token.hasRole(await token.BLACKLISTER(), blacklister.address)).to.be.false;
    await expect(token.connect(blacklister).addBlacklister(owner.address)).to.be.reverted;
  });
});
