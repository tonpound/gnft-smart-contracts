import { ethers } from "hardhat";
const utils = require("../utils");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const gnft = "0x2e86fA4440d93b1BFfEa5cA673314ef54216D0a8";
    const comptroller = "0x1775286Cbe9db126a95AbF52c58a3214FCA26803";
    const args = [gnft, comptroller];

    await utils.deployAndVerify("SegmentManagement", args);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
