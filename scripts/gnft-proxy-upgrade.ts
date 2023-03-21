import { ethers } from "hardhat";
const { getContractAt } = ethers;

const gnftImplPrevious = "0x2D2282691022b659b52d945a5145B49c66F46ab5";;
const gnftImplLatest = "0x812198a973fb64ed4696Fb959Db57B4555f93f0A";
const gnftProxy = "0x3a487ddbC5d704D22EB3A1d9f345065744E10f3C";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const gnft = await getContractAt("gNFT", gnftProxy);

    await gnft.upgradeTo(gnftImplLatest);
    console.log("Upgrade successful");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
