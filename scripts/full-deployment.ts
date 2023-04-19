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
    const networkName = hre.network.name;

    const gNFTImpl = await utils.deployAndVerify("gNFT", []);
    const gNFT = await utils.deployAndVerify("ERC1967Proxy", [gNFTImpl.address, "0x"]);

    const segmentImpl = await utils.deployAndVerify("SegmentManagement", [gNFT.address, comptroller]);
    const segment = await utils.deployAndVerify("ERC1967Proxy", [segmentImpl.address, "0x"]);

    const vaultImpl = await utils.deployAndVerify("Vault", []);
    const treasuryViewer = await utils.deployAndVerify("TreasuryViewer", []);

    const treasuryImpl = await utils.deployAndVerify("Treasury", []);
    const treasury = await utils.deployAndVerify("ERC1967Proxy", [treasuryImpl.address, "0x"]);

    const gNFTProxified = await getContractAt("gNFT", gNFT.address);
    await gNFTProxified.initialize(
        "Tonpound Governance NFT", 
        "gNFT", 
        segment.address
    );
    console.log("gNFT has been initialized");

    const segmentProxified = await getContractAt("SegmentManagement", segment.address);
    await segmentProxified.initialize(
        vaultImpl.address, 
        manager, 
        pauser
    );
    console.log("SegmentManagement has been initialized");

    const treasuryProxified = await getContractAt("Treasury", treasury.address);
    await treasuryProxified.initialize(
        comptroller
    );
    console.log("Treasury has been initialized");


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
