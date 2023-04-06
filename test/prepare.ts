import { ethers, tracer, upgrades } from "hardhat";
import { Contract } from "ethers";
const { getSigners, getContractAt } = ethers;
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

// Constants
const name = "Tonpound Governance NFT";
const symbol = "gNFT";
const nameTPI = "Tonpound Token";
const symbolTPI = "TPI";
const nameMarketETH = "Tonpound Market ETH";
const symbolMarketETH = "tWETH";
const nameMarketUSD = "Tonpound Market USD";
const symbolMarketUSD = "tUSD";

export interface prepareEnvResult {
    gnft: Contract;
    treasury: Contract;
    segmentManagement: Contract;
    comptroller: Contract;
    oracle: Contract;
    tpi: Contract;
    weth: Contract;
    usd: Contract;

    owner: SignerWithAddress;
    alice: SignerWithAddress;
    bob: SignerWithAddress;
    manager: SignerWithAddress;
    pauser: SignerWithAddress;
}

export async function prepareEnv(): Promise<prepareEnvResult> {
    const [owner, alice, bob, manager, pauser] = await getSigners();

    const Proxy = await ethers.getContractFactory("Proxy_mock");
    const Oracle = await ethers.getContractFactory("OracleMock");
    const oracle = await Oracle.deploy();
    const ERC20 = await ethers.getContractFactory("ERC20Mock");
    const tpi = await ERC20.deploy(nameTPI, symbolTPI);
    const weth = await ERC20.deploy(nameMarketETH, symbolMarketETH);
    const usd = await ERC20.deploy(nameMarketUSD, symbolMarketUSD);
    const Comptroller = await ethers.getContractFactory("ComptrollerMock");
    const comptroller = await Comptroller.deploy();

    const TreasuryV1 = await ethers.getContractFactory("TreasuryMockV1");
    const gNFTV1 = await ethers.getContractFactory("gNFTMockV1");
    const gnftImpl = await gNFTV1.deploy();
    const gnftProxy = await Proxy.deploy(gnftImpl.address, "0x");
    const gnft = await getContractAt("gNFTMockV1", gnftProxy.address);

    const treasury = await upgrades.deployProxy(TreasuryV1, [comptroller.address]);
    const Vault = await ethers.getContractFactory("Vault");
    const vaultImplementation = await Vault.deploy();
    const SegmentManagement = await ethers.getContractFactory("SegmentManagement");
    const segmentManagementImpl = await SegmentManagement.deploy(
        gnftProxy.address,
        comptroller.address
    );
    const segmentManagementProxy = await Proxy.deploy(segmentManagementImpl.address, "0x");
    const segmentManagement = await getContractAt(
        "SegmentManagement",
        segmentManagementProxy.address
    );
    await segmentManagement.initialize(
        vaultImplementation.address,
        manager.address,
        pauser.address
    );

    await gnft.initialize(name, symbol, segmentManagement.address);

    await comptroller.initialize(oracle.address, treasury.address, gnft.address, tpi.address);
    await comptroller.supportMarket(weth.address);
    await comptroller.supportMarket(usd.address);
    await comptroller.enterMarkets([weth.address]);

    tracer.nameTags[owner.address] = "owner";
    tracer.nameTags[alice.address] = "alice";
    tracer.nameTags[bob.address] = "bob";
    tracer.nameTags[manager.address] = "manager";
    tracer.nameTags[pauser.address] = "pauser";
    tracer.nameTags[weth.address] = "weth";
    tracer.nameTags[usd.address] = "usd";
    tracer.nameTags[tpi.address] = "tpi";
    tracer.nameTags[oracle.address] = "oracle";
    tracer.nameTags[comptroller.address] = "comptroller";
    tracer.nameTags[segmentManagement.address] = "segmentManagement";
    tracer.nameTags[treasury.address] = "treasury";
    tracer.nameTags[gnft.address] = "gnft";

    return {
        gnft,
        treasury,
        segmentManagement,
        comptroller,
        oracle,
        tpi,
        weth,
        usd,

        owner,
        alice,
        bob,
        manager,
        pauser,
    };
}
