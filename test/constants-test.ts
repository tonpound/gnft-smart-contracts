import { ethers } from "hardhat";
import { expect } from "chai";

describe("Reading parameters", function () {
    it("Getting bytes", async () => {
        const Constants = await ethers.getContractFactory("ConstantsMock");
        const constants = await Constants.deploy();

        console.log(await constants.concatM());

        expect(await constants.compare()).to.equal(true);
    });
});
