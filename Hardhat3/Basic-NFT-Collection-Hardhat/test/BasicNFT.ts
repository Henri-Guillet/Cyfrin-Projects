import { network } from "hardhat";
import { describe, it } from "node:test";
import BasicNFT from "../ignition/modules/BasicNFT.js";
import assert from "node:assert/strict";

describe("Basic NFT test", async function(){
    // Initialize connection
    const { viem, ignition, networkHelpers} = await network.connect()
    const PUG_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    //Deploy contract
    async function deployFixture(){
        const { basicNFT } = await ignition.deploy(BasicNFT);
        return { basicNFT }
    } 
    
    it("Test the name of the NFT", async function() {
    //Load fixture
    const { basicNFT } = await networkHelpers.loadFixture(deployFixture);

    //Get contract
    const dogContract = await viem.getContractAt("BasicNFT", basicNFT.address);
    const tokenName = await dogContract.read.name();

    //Test
    assert.equal(tokenName , "Dogie")
    })

    it("Mint is working, balance is 1", async function(){
     //Load fixture
     const { basicNFT } = await networkHelpers.loadFixture(deployFixture);
     
    //Get contract
    const dogContract = await viem.getContractAt("BasicNFT", basicNFT.address);

    //Test
    await dogContract.write.mint([PUG_URI]);
    const [ signer1 ] = await viem.getWalletClients();
    const balance = await dogContract.read.balanceOf([signer1.account.address])
    assert.equal(balance, 1n)
    })

    it("Corresponding token URI is correct", async function(){
      //Load fixture
      const { basicNFT } = await networkHelpers.loadFixture(deployFixture);
     
      //Get contract
      const dogContract = await viem.getContractAt("BasicNFT", basicNFT.address);
      
      //Test
      await dogContract.write.mint([PUG_URI]);
      const pugURI = await dogContract.read.tokenURI([0n]);
      assert.equal(pugURI, PUG_URI);      
    })

})