import { ethers } from "hardhat";
const { getContractAt } = ethers;

const vault = "0x8239ce5716ED6c7fa63Cb65079f082A5Def228c0";
const manager = "0x3aA3595cB441E7e4c6213aC95D81058AEC66d6cc";
const pauser = "0x624539b4171c4a4FA652165352952f7b4B2Ca166";
const segmentProxy = "0x82018eeb2EB992b98d12CaDA73E55a30E00c84d5";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    const networkName = hre.network.name;

    const segment = await getContractAt("SegmentManagement", segmentProxy);
    await segment.initialize(vault, manager, pauser/*, {
        gasLimit: 500000,
    }*/);
    console.log("SegmentManagement have been initialized");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
