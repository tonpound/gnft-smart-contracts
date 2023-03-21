import { expect } from "chai";
import { prepareEnv } from "./prepare";
const { parseEther } = ethers.utils;
const { getContractAt } = ethers;
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

const name = "Tonpound Governance NFT";
const symbol = "gNFT";

describe("Testing gNFT UUPS proxy deployment", function () {
    it("Deploy test", async () => {
        const { gnft, segmentManagement, comptroller, owner, bob, manager, pauser } =
            await loadFixture(prepareEnv);

        expect(await gnft.name()).to.equal(name);
        expect(await gnft.symbol()).to.equal(symbol);

        const ownerRole = await segmentManagement.DEFAULT_ADMIN_ROLE();
        const managerRole = await segmentManagement.MANAGER_ROLE();
        const pauserRole = await segmentManagement.PAUSER_ROLE();
        expect(await segmentManagement.hasRole(ownerRole, owner.address)).to.equal(true);
        expect(await segmentManagement.hasRole(managerRole, manager.address)).to.equal(true);
        expect(await segmentManagement.hasRole(pauserRole, pauser.address)).to.equal(true);
        await expect(
            segmentManagement.connect(bob).initialize(bob.address, bob.address, bob.address)
        ).to.be.revertedWith("Initializable: contract is already initialized");
    });

    it("Upgrade gNFT test", async () => {
        const { gnft, segmentManagement, comptroller, oracle, weth, bob, owner, manager, pauser } =
            await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";
        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("1000"));
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);

        expect(await gnft.tokenURI(0)).to.equal("Not supported0");

        const ImplV2 = await ethers.getContractFactory("gNFTMockV2");
        const implV2 = await ImplV2.deploy();
        const lowerAddress = owner.address.toString().toLowerCase();
        const defaultRole = await segmentManagement.DEFAULT_ADMIN_ROLE();
        await segmentManagement.grantRole(defaultRole, bob.address);
        await segmentManagement.renounceRole(defaultRole, owner.address);

        const gnftProxy = await getContractAt("UUPSUpgradeable", gnft.address);
        await expect(gnftProxy.upgradeTo(implV2.address)).to.be.revertedWithCustomError(
            gnft,
            "Auth"
        );
        await segmentManagement.connect(bob).grantRole(defaultRole, owner.address);
        await gnftProxy.upgradeTo(implV2.address);
        const upgraded = await getContractAt("gNFTMockV2", gnft.address);

        expect(await upgraded.tokenURI(0)).to.equal("2-0");
        expect(await upgraded.name()).to.equal(name);
        expect(await upgraded.symbol()).to.equal(symbol);
        await expect(gnft.connect(bob).initialize("Bob", "Bob", bob.address)).to.be.revertedWith(
            "Initializable: contract is already initialized"
        );
    });

    it("Upgrade Treasury test", async () => {
        const { gnft, segmentManagement, comptroller, treasury, owner, bob, manager, pauser } =
            await loadFixture(prepareEnv);

        expect(await treasury.version()).to.equal(1);
        const weight = await treasury.totalRegisteredWeight();
        const remaining = await treasury.rewardsClaimRemaining();

        const ImplV2 = await ethers.getContractFactory("TreasuryMockV2");
        const defaultRole = await segmentManagement.DEFAULT_ADMIN_ROLE();
        await segmentManagement.grantRole(defaultRole, bob.address);
        await segmentManagement.renounceRole(defaultRole, owner.address);
        await expect(upgrades.upgradeProxy(treasury.address, ImplV2)).to.be.revertedWithCustomError(
            treasury,
            "Auth"
        );
        await segmentManagement.connect(bob).grantRole(defaultRole, owner.address);
        const upgraded = await upgrades.upgradeProxy(treasury.address, ImplV2);

        expect(await upgraded.version()).to.equal(2);
        expect(await upgraded.TONPOUND_COMPTROLLER()).to.equal(comptroller.address);
        expect(await upgraded.totalRegisteredWeight()).to.equal(weight);
        expect(await upgraded.rewardsClaimRemaining()).to.be.lessThan(remaining);
        await expect(upgraded.connect(bob).initialize(comptroller.address)).to.be.revertedWith(
            "Initializable: contract is already initialized"
        );
    });
});
