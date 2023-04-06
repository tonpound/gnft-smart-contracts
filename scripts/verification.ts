import { ethers } from "hardhat";

const impl_address = "0x2e86fA4440d93b1BFfEa5cA673314ef54216D0a8";

const arg1 = "0xE9dFa04C140904253242a0cC44f29f725626b43f";
const arg2 = "0x";
const args0 = [arg1, arg2];
const args1 = [];

async function main() {
    const [deployer] = await ethers.getSigners();
    const networkName = hre.network.name;

    if (networkName !== "hardhat" && networkName !== "localhost") {
        console.log("Verifying...");
        try {
            await hre.run("verify:verify", {
                address: impl_address,
                constructorArguments: args0
            });
            console.log("Contract is Verified");
        } catch (error: any) {
            console.log("Failed in plugin", error.pluginName);
            console.log("Error name", error.name);
            console.log("Error message", error.message);
        }
    }
    console.log("Verified address:", impl_address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
