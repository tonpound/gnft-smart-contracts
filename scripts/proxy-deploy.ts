import { ethers } from "hardhat";
const utils = require("./utils");

const impl_address = "0xE46f8434a606F2F1B624904c3EA63ab126a6054b";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    await utils.deployAndVerify("ERC1967Proxy", [impl_address, "0x"]);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
