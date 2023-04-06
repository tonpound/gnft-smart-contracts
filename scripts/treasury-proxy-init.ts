import { ethers } from "hardhat";
const { getContractAt } = ethers;

const comptroller = "0x1775286Cbe9db126a95AbF52c58a3214FCA26803";
const treasuryImpl = "";
const treasuryProxy = "0x0529CEa607586B33148B77c165f88362c9B00B11";

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
