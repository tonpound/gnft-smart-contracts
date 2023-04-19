import { ethers } from "hardhat";
const utils = require("./utils");
const { getContractAt } = ethers;

const comptroller = "0x7015B9053F26c95981109C72a2e91c588035ECBF";

// Mainnet
// const manager = "0x3aA3595cB441E7e4c6213aC95D81058AEC66d6cc";
// const pauser = "0x624539b4171c4a4FA652165352952f7b4B2Ca166";

// Testnet
const manager = "0x03eE60B0De0d9b48C5A09E73c3fdF80fEB86AeEF";
const pauser = "0x03eE60B0De0d9b48C5A09E73c3fdF80fEB86AeEF";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
