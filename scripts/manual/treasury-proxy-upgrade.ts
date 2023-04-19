import { ethers } from "hardhat";
const { getContractAt } = ethers;

const treasuryImplPrevious = "";
const treasuryImplLatest = "";
const treasuryProxy = "0x0529CEa607586B33148B77c165f88362c9B00B11";

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
