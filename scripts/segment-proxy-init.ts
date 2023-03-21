import { ethers } from "hardhat";
const { getContractAt } = ethers;

const vault = "0x83c83f349B17CbcD70D7Be7BFc0d60e37dea281f";
const admin = "0x03eE60B0De0d9b48C5A09E73c3fdF80fEB86AeEF";
const segmentProxy = "0x782F195f6D63eD01EEb00Ce62Bd5C3b821454412";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const segment = await getContractAt("SegmentManagement", segmentProxy);
    await segment.initialize(vault, admin, admin, {
        gasLimit: 500000,
    });
    console.log("SegmentManagement have been initialized");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
