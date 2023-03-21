import { ethers } from "hardhat";
const { getContractAt } = ethers;

const segment = "0x782F195f6D63eD01EEb00Ce62Bd5C3b821454412";
const gnftProxy = "0x3a487ddbC5d704D22EB3A1d9f345065744E10f3C";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const gnft = await getContractAt("gNFT", gnftProxy);

    await gnft.initialize("Tonpound Governance NFT", "gNFT", segment, {
        gasLimit: 500000,
    });
    console.log("gNFT have been initialized");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
