import { expect } from "chai";
import { prepareEnvResult, prepareEnv } from "./prepare";
const { parseEther } = ethers.utils;
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

describe("Testing gNFT minting", function () {
    it("Activating segment with proof", async () => {
        const {
            gnft,
            segmentManagement,
            comptroller,
            oracle,
            weth,
            usd,
            bob,
            alice,
            manager,
            owner,
        } = await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";

        const values1 = [[bob.address, 1]];
        const tree1 = StandardMerkleTree.of(values1, ["address", "uint256"]);
        let bobProof1;
        let root1;
        for (const [i, v] of tree1.entries()) {
            if (v[0] === bob.address) {
                bobProof1 = tree1.getProof(i);
            }
        }
        root1 = tree1.root;
        console.log("Merkle Root1:", root1);

        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.connect(bob).enterMarkets([weth.address]);
        await weth.transfer(bob.address, parseEther("0.001"));
        await weth.transfer(bob.address, parseEther("1000"));
        await segmentManagement.connect(bob)[mintMarkets]([weth.address], 0, []);

        const priceTo1Segment = await segmentManagement.getActivationPrice(0, 1, true);
        await expect(
            segmentManagement
                .connect(bob)
                .activateSegmentWithProof(0, bob.address, 1, bobProof1, weth.address)
        ).to.be.revertedWithCustomError(segmentManagement, "InvalidProof");
        await expect(segmentManagement.connect(owner).setMerkleRoot(root1)).to.be.reverted;
        await expect(segmentManagement.connect(manager).setMerkleRoot(root1))
            .to.emit(segmentManagement, "AirdropMerkleRootChanged")
            .withArgs("0x0000000000000000000000000000000000000000000000000000000000000000", root1);

        await segmentManagement
            .connect(alice)
            .activateSegmentWithProof(0, bob.address, 1, bobProof1, weth.address);
        const data1 = await gnft.getTokenData(0);
        expect(data1.slot0.activeSegment).to.equal(1);

        await expect(
            segmentManagement
                .connect(bob)
                .activateSegmentWithProof(0, bob.address, 1, bobProof1, weth.address)
        ).to.be.revertedWithCustomError(segmentManagement, "DiscountUsed");

        const values2 = [
            [bob.address, 1],
            [bob.address, 2],
        ];
        const tree2 = StandardMerkleTree.of(values2, ["address", "uint256"]);
        let bobProof2;
        let root2;
        for (const [i, v] of tree2.entries()) {
            if (v[0] === bob.address && v[1] === 2) {
                bobProof2 = tree2.getProof(i);
            }
        }
        root2 = tree2.root;
        console.log("Merkle Root2:", root2);

        await segmentManagement.connect(manager).setMerkleRoot(root2);
        await expect(
            segmentManagement
                .connect(bob)
                .activateSegmentWithProof(0, bob.address, 1, bobProof1, weth.address)
        ).to.be.revertedWithCustomError(segmentManagement, "DiscountUsed");
        await segmentManagement
            .connect(alice)
            .activateSegmentWithProof(0, bob.address, 2, bobProof2, weth.address);
        const data2 = await gnft.getTokenData(0);
        expect(data2.slot0.activeSegment).to.equal(2);
    });
});
