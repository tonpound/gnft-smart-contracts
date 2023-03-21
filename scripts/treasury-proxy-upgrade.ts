import { ethers } from "hardhat";
const { getContractAt } = ethers;

const treasuryImplPrevious = "0x409a4d1649D9dF34E2AC3C5D005aBff018B00E8d";
const treasuryImplLatest = "0x409a4d1649D9dF34E2AC3C5D005aBff018B00E8d";
const treasuryProxy = "0x510Cea357a331E78003703Aaa2308E93996C3F0d";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const treasury = await getContractAt("Treasury", treasuryProxy);

    await treasury.upgradeTo(treasuryImplLatest, {gasLimit: 200000});
    console.log("Upgrade successful");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
