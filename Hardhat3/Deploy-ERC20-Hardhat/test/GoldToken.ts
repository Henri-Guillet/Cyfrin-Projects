import { describe, it } from "node:test";
import { network } from "hardhat";
import GoldToken from "../ignition/modules/GoldToken.js"
import assert from "node:assert/strict";

describe("GoldToken", async function(){
    // Initialize connection
    const { viem, ignition, networkHelpers } = await network.connect()

    //Deploy contract
    async function deployTokenFixture(){
        const { goldToken } = await ignition.deploy(GoldToken)
        return { goldToken }
    }

    it("Total supply of Gold is 1000", async function(){
        //Use Fixture
        const { goldToken } =  await networkHelpers.loadFixture(deployTokenFixture) 
        
        //Get contract
        const goldContract = await viem.getContractAt("GoldToken", goldToken.address)
        const totalSupply = await goldContract.read.totalSupply()
        assert.equal(totalSupply, 1000n)
    })
})