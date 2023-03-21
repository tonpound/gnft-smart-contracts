import { expect } from "chai";
import { prepareEnv } from "./prepare";
const { parseEther } = ethers.utils;
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");
const abi = ethers.utils.defaultAbiCoder;

// Constants
const name = "Tonpound Governance NFT";
const version = "1";

describe("Testing gNFT permit approval", function () {
    it("Permit test", async () => {
        const { gnft, segmentManagement, comptroller, oracle, weth, owner, bob } =
            await loadFixture(prepareEnv);
        const mintMarkets = "mint(address[],uint8,uint256[])";
        await oracle.setPrice(weth.address, parseEther("1000"));
        await comptroller.enterMarkets([weth.address]);
        await segmentManagement[mintMarkets]([weth.address], 0, []);
        const tokenId = 0;

        const chainId = 31337;
        const verifyingContract = gnft.address;
        const curTime = await time.latest();
        const deadlineBad = curTime - 10000;
        const deadlineGood = curTime + 10000;
        const nonceGood = await gnft.nonces(owner.address);
        const nonceBad = (await gnft.nonces(owner.address)).add(100);
        const sigDeadlineBad = ethers.utils.splitSignature(
            await owner._signTypedData(
                {
                    name,
                    version,
                    chainId,
                    verifyingContract,
                },
                {
                    Permit: [
                        {
                            name: "spender",
                            type: "address",
                        },
                        {
                            name: "tokenId",
                            type: "uint256",
                        },
                        {
                            name: "nonce",
                            type: "uint256",
                        },
                        {
                            name: "expiry",
                            type: "uint256",
                        },
                    ],
                },
                {
                    spender: bob.address,
                    tokenId: tokenId,
                    nonce: nonceGood,
                    expiry: deadlineBad,
                }
            )
        );
        const sigNonceBad = ethers.utils.splitSignature(
            await owner._signTypedData(
                {
                    name,
                    version,
                    chainId,
                    verifyingContract,
                },
                {
                    Permit: [
                        {
                            name: "spender",
                            type: "address",
                        },
                        {
                            name: "tokenId",
                            type: "uint256",
                        },
                        {
                            name: "nonce",
                            type: "uint256",
                        },
                        {
                            name: "expiry",
                            type: "uint256",
                        },
                    ],
                },
                {
                    spender: bob.address,
                    tokenId: tokenId,
                    nonce: nonceBad,
                    expiry: deadlineGood,
                }
            )
        );
        const sigGood = ethers.utils.splitSignature(
            await owner._signTypedData(
                {
                    name,
                    version,
                    chainId,
                    verifyingContract,
                },
                {
                    Permit: [
                        {
                            name: "spender",
                            type: "address",
                        },
                        {
                            name: "tokenId",
                            type: "uint256",
                        },
                        {
                            name: "nonce",
                            type: "uint256",
                        },
                        {
                            name: "expiry",
                            type: "uint256",
                        },
                    ],
                },
                {
                    spender: bob.address,
                    tokenId: tokenId,
                    nonce: nonceGood,
                    expiry: deadlineGood,
                }
            )
        );

        await expect(
            gnft.permit(
                bob.address,
                tokenId,
                nonceGood,
                deadlineBad,
                sigDeadlineBad.v,
                sigDeadlineBad.r,
                sigDeadlineBad.s
            )
        ).to.be.revertedWithCustomError(gnft, "PermitSignatureExpired");
        await expect(
            gnft.connect(bob).transferFrom(owner.address, bob.address, tokenId)
        ).to.be.revertedWith("ERC721: caller is not token owner or approved");
        await expect(
            gnft.permit(
                bob.address,
                tokenId,
                nonceGood,
                deadlineGood,
                sigDeadlineBad.v,
                sigDeadlineBad.r,
                sigDeadlineBad.s
            )
        ).to.be.revertedWithCustomError(gnft, "PermitInvalidSignature");
        await expect(
            gnft.permit(
                bob.address,
                tokenId,
                nonceBad,
                deadlineGood,
                sigNonceBad.v,
                sigNonceBad.r,
                sigNonceBad.s
            )
        ).to.be.revertedWithCustomError(gnft, "PermitInvalidNonce");
        await gnft.permit(
            bob.address,
            tokenId,
            nonceGood,
            deadlineGood,
            sigGood.v,
            sigGood.r,
            sigGood.s
        );
        await gnft.connect(bob).transferFrom(owner.address, bob.address, tokenId);
        expect(await gnft.ownerOf(tokenId)).to.equal(bob.address);
    });
});
