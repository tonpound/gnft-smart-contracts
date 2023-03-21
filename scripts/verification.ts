import { ethers } from "hardhat";

const impl_address = "0x2D2282691022b659b52d945a5145B49c66F46ab5";

const arg1 = "0x3a487ddbC5d704D22EB3A1d9f345065744E10f3C";
const arg2 = "0x396Caaa6d2ddf61a981C9A098aF390136138F83c";
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
                constructorArguments: args1
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
