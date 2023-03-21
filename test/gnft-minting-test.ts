import { expect } from "chai";
import { prepareEnvResult, prepareEnv } from "./prepare";
const { parseEther } = ethers.utils;
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Testing gNFT minting", function () {
    it("Minting new nft", async () => {
        const { gnft, segmentManagement, comptroller, oracle, weth, usd, bob, alice } =
            await loadFixture(prepareEnv);
        const mint = "mint(address[])";
        const mintMarkets = "mint(address[],uint8,uint256[])";

        await comptroller.connect(bob).enterMarkets([usd.address]);
        await expect(
            segmentManagement.connect(bob)[mint]([weth.address])
        ).to.be.revertedWithCustomError(segmentManagement, "OracleFailed");
        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("0.001"));
        await expect(
            segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, [])
        ).to.be.revertedWithCustomError(segmentManagement, "FailedLiquidityCheck");
        await weth.transfer(bob.address, parseEther("1000"));
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);
        const token0 = 0;
        expect(await gnft.ownerOf(token0)).to.equal(bob.address);
        const data = await gnft.getTokenData(token0);
        expect(data.slot0.activeSegment).to.equal(0);
        expect(data.slot0.voteWeight).to.equal(1);
        expect(data.slot0.rewardWeight).to.equal(1);
        expect(data.slot0.completionTimestamp).to.equal(0);
        await oracle.setPrice(usd.address, parseEther("1"));
        await weth.transfer(alice.address, parseEther("0.099"));
        await expect(
            segmentManagement.connect(alice)[mint]([weth.address])
        ).to.be.revertedWithCustomError(segmentManagement, "FailedLiquidityCheck");
        await comptroller.connect(alice).enterMarkets([weth.address]);
        await expect(
            segmentManagement.connect(alice)[mint]([weth.address])
        ).to.be.revertedWithCustomError(segmentManagement, "FailedLiquidityCheck");
        await weth.transfer(alice.address, parseEther("0.001"));
        await segmentManagement.connect(alice)[mint]([weth.address]);
        const token1 = 1;
        const dataA = await gnft.getTokenData(token1);
        expect(await gnft.ownerOf(token1)).to.equal(alice.address);
        expect(dataA.slot1.lockedVaultShares).to.equal(0);
    });
});
