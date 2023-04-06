import { ethers } from "hardhat";
const { getContractAt } = ethers;

const segment = "0x82018eeb2EB992b98d12CaDA73E55a30E00c84d5";
const gnftProxy = "0x2e86fA4440d93b1BFfEa5cA673314ef54216D0a8";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const gnft = await getContractAt("gNFT", gnftProxy);

    await gnft.initialize("Tonpound Governance NFT", "gNFT", segment/*, {
        gasLimit: 500000,
    }*/);
    console.log("gNFT have been initialized");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
