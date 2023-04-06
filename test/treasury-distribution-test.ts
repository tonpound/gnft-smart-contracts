import { expect } from "chai";
import { prepareEnvResult, prepareEnv } from "./prepare";
const { parseEther } = ethers.utils;
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Testing Treasury rewards distribution", function () {
    it("Registering incoming rewards", async () => {
        const {
            gnft,
            treasury,
            segmentManagement,
            comptroller,
            oracle,
            tpi,
            weth,
            usd,
            bob,
            alice,
        } = await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";
        const activateSegmentMarket = "activateSegments(uint256,uint8,address)";

        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("1000"));
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);
        const token0 = 0;

        const priceTo12Segments = await segmentManagement.getActivationPrice(token0, 12, false);
        const liquidityForLock = await segmentManagement.quoteLiquidityForLock(weth.address, 0);
        await tpi.transfer(bob.address, priceTo12Segments);
        await tpi.connect(bob).approve(segmentManagement.address, priceTo12Segments);
        const bobBalanceBefore = await weth.balanceOf(bob.address);

        const rewardUSD = parseEther("1001");
        await usd.transfer(treasury.address, rewardUSD);
        await treasury.distributeRewards();
        expect(await treasury.getRewardTokensLength()).to.equal(2);
        expect((await treasury.getRewardTokens()).length).to.equal(2);
        expect(await treasury.getRewardTokensAtIndex(0)).to.equal(weth.address);
        expect(await treasury.getRewardTokensAtIndex(1)).to.equal(usd.address);
        await expect(
            segmentManagement.connect(bob)[activateSegmentMarket](token0, 12, weth.address)
        ).to.be.revertedWith("ERC20: insufficient allowance");
        await weth.connect(bob).approve(segmentManagement.address, liquidityForLock);
        await segmentManagement.connect(bob)[activateSegmentMarket](token0, 12, weth.address);
        const bobBalanceAfter = await weth.balanceOf(bob.address);
        expect(bobBalanceBefore.sub(bobBalanceAfter)).to.equal(liquidityForLock);
        const data = await gnft.getTokenData(token0);
        expect(data.slot0.activeSegment).to.equal(12);
        expect(data.slot0.lockedMarket).to.equal(weth.address);
        expect(data.slot1.lockedVaultShares).to.equal(liquidityForLock);
        expect(await treasury.registeredTokenIds(token0)).to.equal(true);

        await time.increase(3600 * 24 * 365);
        const usdBobBalanceBefore = await usd.balanceOf(bob.address);
        await treasury.distributeRewards();
        const pending = await treasury.pendingReward(usd.address, 0);
        await expect(
            treasury.connect(alice).claimReward(token0, usd.address)
        ).to.be.revertedWithCustomError(treasury, "InvalidTokenOwnership");
        await treasury.connect(bob).claimReward(token0, usd.address);
        const usdBobBalanceAfter = await usd.balanceOf(bob.address);
        expect(usdBobBalanceAfter.sub(usdBobBalanceBefore)).to.equal(rewardUSD);
        expect(pending).to.equal(rewardUSD);
    });

    it("Distribute over multiple users", async () => {
        const {
            gnft,
            treasury,
            segmentManagement,
            comptroller,
            oracle,
            tpi,
            weth,
            usd,
            bob,
            alice,
        } = await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";
        const activateSegmentMarket = "activateSegments(uint256,uint8,address)";

        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await comptroller.connect(alice).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("1000"));
        await weth.transfer(alice.address, parseEther("1000"));
        for (let i = 0; i < 10; i++) {
            await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);
        }
        const token0 = 0;

        const priceTo12Segments = await segmentManagement.getActivationPrice(token0, 12, false);
        const liquidityForLock = await segmentManagement.quoteLiquidityForLock(weth.address, 0);
        await tpi.transfer(bob.address, priceTo12Segments.mul(10));
        await tpi.connect(bob).approve(segmentManagement.address, priceTo12Segments.mul(10));
        await weth.connect(bob).approve(segmentManagement.address, liquidityForLock.mul(10));
        await segmentManagement.connect(bob)[activateSegmentMarket](token0, 12, weth.address);
        for (let i = 1; i < 10; i++) {
            await segmentManagement.connect(bob)[activateSegmentMarket](i, 12, weth.address);
        }
        const mergeData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
        const token10 = 10; // Bob's Emerald
        const token11 = 11; // Alice's Topaz
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 1, mergeData);
        const bobBalanceBefore = await usd.balanceOf(bob.address);
        await segmentManagement.connect(alice)[mintMarkets]([weth.address], 0, []);
        await tpi.transfer(alice.address, priceTo12Segments);
        await tpi.connect(alice).approve(segmentManagement.address, priceTo12Segments);
        await weth.connect(alice).approve(segmentManagement.address, liquidityForLock);
        await segmentManagement.connect(alice)[activateSegmentMarket](token11, 12, weth.address);
        const aliceBalanceBefore = await usd.balanceOf(alice.address);

        const rewardUSD = parseEther("1100");
        await usd.transfer(treasury.address, rewardUSD);
        await treasury.distributeReward(usd.address);
        expect(await treasury.rewardsClaimRemaining()).to.be.greaterThan(0);
        await time.increase(3600 * 24 * 365);
        expect(await treasury.rewardsClaimRemaining()).to.equal(0);
        await treasury.connect(alice).claimReward(token11, usd.address);
        const aliceBalanceAfter = await usd.balanceOf(alice.address);
        expect(aliceBalanceAfter.sub(aliceBalanceBefore)).to.equal(rewardUSD.div(11));
        await time.increase(3600 * 24);
        await treasury.connect(bob).claimRewards(3);
        const bobBalanceAfter = await usd.balanceOf(bob.address);
        expect(bobBalanceAfter.sub(bobBalanceBefore)).to.equal(rewardUSD.div(11));
    });

    it("De-registering half-way", async () => {
        const {
            gnft,
            treasury,
            segmentManagement,
            comptroller,
            oracle,
            tpi,
            weth,
            usd,
            bob,
            alice,
        } = await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";
        const activateSegmentMarket = "activateSegments(uint256,uint8,address)";

        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await comptroller.connect(alice).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("1000"));
        await weth.transfer(alice.address, parseEther("1000"));
        for (let i = 0; i < 10; i++) {
            await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);
        }
        const token0 = 0;

        const priceTo12Segments = await segmentManagement.getActivationPrice(token0, 12, false);
        const liquidityForLock = await segmentManagement.quoteLiquidityForLock(weth.address, 0);
        await tpi.transfer(bob.address, priceTo12Segments.mul(10));
        await tpi.connect(bob).approve(segmentManagement.address, priceTo12Segments.mul(10));
        await weth.connect(bob).approve(segmentManagement.address, liquidityForLock.mul(10));
        await segmentManagement.connect(bob)[activateSegmentMarket](token0, 12, weth.address);
        for (let i = 1; i < 10; i++) {
            await segmentManagement.connect(bob)[activateSegmentMarket](i, 12, weth.address);
        }
        const mergeData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0];
        const token10 = 10; // Bob's Emerald
        const token11 = 11; // Alice's Topaz
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 1, mergeData);
        const bobBalanceBefore = await usd.balanceOf(bob.address);
        await segmentManagement.connect(alice)[mintMarkets]([weth.address], 0, []);
        await tpi.transfer(alice.address, priceTo12Segments);
        await tpi.connect(alice).approve(segmentManagement.address, priceTo12Segments);
        await weth.connect(alice).approve(segmentManagement.address, liquidityForLock);
        await segmentManagement.connect(alice)[activateSegmentMarket](token11, 12, weth.address);
        const aliceBalanceBefore = await usd.balanceOf(alice.address);

        const rewardUSD1 = parseEther("1100");
        await usd.transfer(treasury.address, rewardUSD1);
        await treasury.distributeReward(usd.address);
        expect(await treasury.rewardsClaimRemaining()).to.be.greaterThan(0);
        await time.increase(3600 * 24 * 200);

        const aliceWETHBalanceBefore = await weth.balanceOf(alice.address);
        await segmentManagement.connect(alice).unlockLiquidity(token11);
        const pendingAlice0 = await treasury.pendingReward(usd.address, 11);
        const aliceWETHBalanceAfter = await weth.balanceOf(alice.address);
        expect(aliceWETHBalanceAfter.sub(aliceWETHBalanceBefore)).to.equal(liquidityForLock);

        const rewardUSD2 = parseEther("1000");
        await usd.transfer(treasury.address, rewardUSD2);
        await treasury.distributeReward(usd.address);

        await time.increase(3600 * 24 * 200);
        expect(await treasury.rewardsClaimRemaining()).to.equal(0);

        const pendingAlice1 = await treasury.pendingReward(usd.address, token11);
        console.log(pendingAlice1, pendingAlice0);
        expect(pendingAlice1).to.equal(rewardUSD1.div(11));
        await treasury.connect(alice).claimReward(token11, usd.address);
        const aliceBalanceAfter = await usd.balanceOf(alice.address);
        expect(aliceBalanceAfter.sub(aliceBalanceBefore)).to.equal(pendingAlice1);

        await treasury.connect(bob).claimRewards(4);
        const bobBalanceAfter = await usd.balanceOf(bob.address);
        expect(bobBalanceAfter.sub(bobBalanceBefore)).to.equal(
            rewardUSD1.div(11).add(rewardUSD2.div(10))
        );

        await weth.connect(bob).approve(segmentManagement.address, liquidityForLock);
        await weth.connect(alice).approve(segmentManagement.address, liquidityForLock);
        await expect(
            segmentManagement.connect(bob).lockLiquidity(token11, weth.address)
        ).to.be.revertedWithCustomError(segmentManagement, "InvalidTokenOwnership");
        await segmentManagement.connect(alice).lockLiquidity(token11, weth.address);
    });
});
