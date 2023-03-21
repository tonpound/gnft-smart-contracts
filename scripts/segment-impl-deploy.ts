import { ethers } from "hardhat";
const utils = require("./utils");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const gnft = "0x3a487ddbC5d704D22EB3A1d9f345065744E10f3C";
    const comptroller = "0x396Caaa6d2ddf61a981C9A098aF390136138F83c";
    const args = [gnft, comptroller];

    await utils.deployAndVerify("SegmentManagement", args);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
