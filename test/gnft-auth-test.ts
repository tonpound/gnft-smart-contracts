import { expect } from "chai";
import { prepareEnvResult, prepareEnv } from "./prepare";
const { parseEther } = ethers.utils;
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Testing gNFT authorization modifiers", function () {
    it("Pausing and unpausing gNFT", async () => {
        const {
            gnft,
            segmentManagement,
            comptroller,
            oracle,
            tpi,
            weth,
            bob,
            alice,
            owner,
            pauser,
        } = await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";
        const activateSegments = "activateSegments(uint256,uint8,address)";
        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("1000"));
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);

        const priceTo1Segment = await segmentManagement.getActivationPrice(0, 1, false);
        await tpi.transfer(bob.address, parseEther("10000"));
        await segmentManagement.connect(bob)[activateSegments](0, 1, weth.address);
        const data = await gnft.getTokenData(0);
        expect(data.slot0.activeSegment).to.equal(1);
        await expect(gnft.connect(bob).transferFrom(bob.address, alice.address, 0)).not.to.be
            .reverted;

        const lowerOwnerAddress = owner.address.toString().toLowerCase();
        const pauserRole = await segmentManagement.PAUSER_ROLE();
        await expect(segmentManagement.connect(owner).setPause(true)).to.be.revertedWith(
            `AccessControl: account ${lowerOwnerAddress} is missing role ${pauserRole}`
        );
        await expect(segmentManagement.connect(pauser).setPause(false)).to.be.revertedWith(
            "Pausable: not paused"
        );
        await segmentManagement.connect(pauser).setPause(true);

        await expect(
            gnft.connect(alice).transferFrom(alice.address, bob.address, 0)
        ).to.be.revertedWithCustomError(gnft, "Paused");
        await expect(
            segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, [])
        ).to.be.revertedWith("Pausable: paused");
        await segmentManagement.connect(pauser).setPause(false);
        await gnft.connect(alice).transferFrom(alice.address, bob.address, 0);
    });

    it("Blacklisting in gNFT", async () => {
        const { gnft, segmentManagement, comptroller, oracle, weth, bob, alice, owner, manager } =
            await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";
        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("1000"));
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);

        const lowerOwnerAddress = owner.address.toString().toLowerCase();
        const managerRole = await segmentManagement.MANAGER_ROLE();
        const blacklistRole = await segmentManagement.BLACKLISTED_ROLE();
        await expect(
            segmentManagement.connect(owner).grantRole(blacklistRole, alice.address)
        ).to.be.revertedWith(
            `AccessControl: account ${lowerOwnerAddress} is missing role ${managerRole}`
        );
        await segmentManagement.connect(manager).grantRole(blacklistRole, alice.address);
        await gnft.connect(bob).transferFrom(bob.address, owner.address, 0);
        await expect(gnft.connect(owner).transferFrom(owner.address, alice.address, 0))
            .to.be.revertedWithCustomError(gnft, "BlacklistedUser")
            .withArgs(alice.address);
        await segmentManagement.connect(manager).revokeRole(blacklistRole, alice.address);
        await gnft.connect(owner).transferFrom(owner.address, alice.address, 0);
        await segmentManagement.connect(manager).grantRole(blacklistRole, bob.address);
        await expect(segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []))
            .to.be.revertedWithCustomError(gnft, "BlacklistedUser")
            .withArgs(bob.address);
    });

    it("Pausing Treasury via segmentManagement", async () => {
        const {
            gnft,
            segmentManagement,
            comptroller,
            treasury,
            oracle,
            tpi,
            weth,
            usd,
            bob,
            pauser,
        } = await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";
        const activateSegmentMarket = "activateSegments(uint256,uint8,address)";
        const claimRewardSingle = "claimReward(uint256,address)";

        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("2000"));
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);

        const priceTo12Segments = await segmentManagement.getActivationPrice(0, 12, false);
        const liquidityForLock = await segmentManagement.quoteLiquidityForLock(weth.address, 0);
        await tpi.transfer(bob.address, priceTo12Segments);
        await tpi.connect(bob).approve(segmentManagement.address, priceTo12Segments);

        const rewardUSD = parseEther("1001");
        await usd.transfer(treasury.address, rewardUSD);
        await treasury.distributeRewards();
        await weth.connect(bob).approve(segmentManagement.address, liquidityForLock);
        await segmentManagement.connect(bob)[activateSegmentMarket](0, 12, weth.address);

        await time.increase(3600 * 24 * 365);
        await treasury.distributeRewards();
        await segmentManagement.connect(pauser).setPause(true);
        await expect(
            treasury.connect(bob)[claimRewardSingle](0, usd.address)
        ).to.be.revertedWithCustomError(treasury, "Paused");
        await segmentManagement.connect(pauser).setPause(false);
        await treasury.connect(bob)[claimRewardSingle](0, usd.address);
    });
});
