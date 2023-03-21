import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const config = require("../config.js");
const admin = "0x03eE60B0De0d9b48C5A09E73c3fdF80fEB86AeEF";
const comptroller = "0x9e48773dCF602876C2b16D3ad36f5AEc09A59B2C";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployer, validator, pauser, oracle } = await hre.getNamedAccounts();

    const result = await hre.deployments.deploy("Treasury", {
        from: deployer,
        args: [],
        proxy: {
            proxyContract: 'ERC1967Proxy',
            init: {
                methodName: 'initialize',
                args: [
                    comptroller,
                ],
            }
        },
        log: true,
        autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
    });

    if (hre.network.name != "hardhat") {
        console.log("Verifying contract...");
        try {
            await hre.run("verify:verify", {
                address: result.address,
                constructorArguments: result.args,
            });
            console.log("Contract is Verified");
        } catch (error: any) {
            console.log("Failed in plugin", error.pluginName);
            console.log("Error name", error.name);
            console.log("Error message", error.message);
        }
    }
};

export default func;
func.tags = ["Token"];
