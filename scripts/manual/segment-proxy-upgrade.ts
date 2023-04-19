import { ethers } from "hardhat";
const { getContractAt } = ethers;

const segmentImplPrevious = "";
const segmentLatest = "0xdCD2Cc059bff18F33092EAE878b5813F44f506cc";
const segmentProxy = "0x82018eeb2EB992b98d12CaDA73E55a30E00c84d5";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const vault = await getContractAt("SegmentManagement", segmentProxy);

    await vault.upgradeTo(segmentLatest);
    console.log("Upgrade successful");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
