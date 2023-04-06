import { ethers } from "hardhat";
const { getContractAt } = ethers;

const gnftImplPrevious = "";;
const gnftImplLatest = "0xAeFf026fea6d7A33d72c3D9c91F9Ed2054d4a05B";
const gnftProxy = "0x2e86fA4440d93b1BFfEa5cA673314ef54216D0a8";

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
