import { ethers } from "hardhat";
const { getContractAt } = ethers;

const segmentImplPrevious = "0x6a76BB05Af2559B681fFcD44c662a41EF95B518f";
const segmentLatest = "0xB110452Da913fdF27519FDf5F8ACd7C0A9C7dC6D";
const segmentProxy = "0x782F195f6D63eD01EEb00Ce62Bd5C3b821454412";

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
