import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SolarGreen", function () {
  async function deploy() {
    const [owner, buyer, spender, newOwner] = await ethers.getSigners();

    const SolarGreen = await ethers.getContractFactory("SolarGreen", owner);
    const token = await SolarGreen.deploy(owner.address, owner.address);

    await token.transfer(spender.address, 30);

    return { owner, buyer, spender, newOwner, token };
  }

  it("owner must be admin", async function () {
    const { owner, token } = await loadFixture(deploy);

    expect(await token.hasRole(await token.ADMIN(), owner.address)).to.be.true;
    expect(await token.getAddress()).to.be.properAddress;
  });

  it("should be correct supply", async function () {
    const { token } = await loadFixture(deploy);

    const decimals = BigInt(10) ** (await token.decimals());

    expect(await token.totalSupply()).to.eq(BigInt(100000000) * decimals);
  });

  it("correct transfer to", async function () {
    const { buyer, token } = await loadFixture(deploy);
    const amount = 3;

    await token.transfer(buyer.address, amount);

    const balanceBuyer = await token.balanceOf(buyer.address);
    expect(balanceBuyer).to.equal(amount);
  });

  it("correct transfer from", async function () {
    const { owner, buyer, spender, token } = await loadFixture(deploy);

    const amount = 8;

    await token.approve(spender.address, amount);

    await token.connect(spender).transferFrom(owner.address, buyer.address, amount);

    const balanceBuyer = await token.balanceOf(buyer.address);

    expect(await token.allowance(owner.address, spender.address));
    expect(balanceBuyer).to.eq(amount);
  });

  it("allow to mint new token", async function () {
    const { owner, token } = await loadFixture(deploy);

    const amount = 10;
    const expectedTotalSupply = (await token.totalSupply()) + BigInt(amount);

    await token.mint(owner.address, amount);

    expect(await token.totalSupply()).to.eq(expectedTotalSupply);
  });

  it("allow to burn token", async function () {
    const { owner, token } = await loadFixture(deploy);

    const amount = 8;
    const expectedTotalSupply = (await token.totalSupply()) - BigInt(amount);

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

  it("should add and remove a blacklister", async function () {
    const { buyer: blacklister, token } = await loadFixture(deploy);

    await token.addBlacklister(blacklister.address);

    expect(await token.hasRole(await token.BLACKLISTER(), blacklister.address)).to.be.true;

    await token.removeBlacklister(blacklister.address);

    expect(await token.hasRole(await token.BLACKLISTER(), blacklister.address)).to.be.false;
  });
});
