import { ethers } from "hardhat";
const utils = require("../utils");

const impl_address = "0x2e86fA4440d93b1BFfEa5cA673314ef54216D0a8";

const arg1 = "0xE9dFa04C140904253242a0cC44f29f725626b43f";
const arg2 = "0x";
const args0 = [arg1, arg2];
const args1 = [];

async function main() {
    await utils.verify("TreasuryViewer", []);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
