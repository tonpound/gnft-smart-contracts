import { expect } from "chai";
import { prepareEnvResult, prepareEnv } from "./prepare";
const { parseEther } = ethers.utils;
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Testing gNFT segments", function () {
    it("Activating new segment without completion", async () => {
        const { gnft, segmentManagement, comptroller, oracle, tpi, weth, bob } = await loadFixture(
            prepareEnv
        );
        const mintMarkets = "mint(address[],uint8,uint256[])";
        const activateSegment = "activateSegments(uint256,uint8,address)";
        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("1000"));
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);
        const token0 = 0;

        const priceTo1Segment = await segmentManagement.getActivationPrice(token0, 1, false);
        await expect(
            segmentManagement.connect(bob)[activateSegment](token0, 1, weth.address)
        ).to.be.revertedWith("ERC20: burn amount exceeds balance");
        await tpi.transfer(bob.address, parseEther("10000"));
        await tpi.connect(bob).approve(segmentManagement.address, priceTo1Segment);
        await segmentManagement.connect(bob)[activateSegment](token0, 1, weth.address);
        const data = await gnft.getTokenData(token0);
        expect(data.slot0.activeSegment).to.equal(1);
    });

    it("Completing token with lock", async () => {
        const { gnft, segmentManagement, comptroller, oracle, tpi, weth, bob } = await loadFixture(
            prepareEnv
        );
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
        await weth.transfer(bob.address, liquidityForLock);
        await weth.connect(bob).approve(segmentManagement.address, liquidityForLock);
        await segmentManagement.connect(bob)[activateSegmentMarket](token0, 12, weth.address);
        await expect(
            segmentManagement.connect(bob)[activateSegmentMarket](token0, 1, weth.address)
        ).to.be.revertedWithCustomError(segmentManagement, "AlreadyFullyActivated");
        const data = await gnft.getTokenData(token0);
        expect(data.slot0.activeSegment).to.equal(12);
    });
});
