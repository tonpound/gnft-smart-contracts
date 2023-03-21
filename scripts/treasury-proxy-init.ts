import { ethers } from "hardhat";
const { getContractAt } = ethers;

const comptroller = "0x396Caaa6d2ddf61a981C9A098aF390136138F83c";
const treasuryImpl = "0x409a4d1649D9dF34E2AC3C5D005aBff018B00E8d";
const treasuryProxy = "0x510Cea357a331E78003703Aaa2308E93996C3F0d";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const treasury = await getContractAt("Treasury", treasuryProxy);

    await treasury.initialize(comptroller);
    console.log("Treasury have been initialized");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
