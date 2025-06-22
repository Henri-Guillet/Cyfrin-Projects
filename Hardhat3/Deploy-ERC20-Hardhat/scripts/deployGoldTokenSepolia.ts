import { network } from "hardhat";
import GoldToken from "../ignition/modules/GoldToken.js";

async function deploy (){
    console.log("start deploy")
    const { viem, ignition, networkName } = await network.connect("sepolia")
    console.log(`Connected to ${networkName}`)
    const { goldToken } = await ignition.deploy(GoldToken) 
    console.log(`deployed at ${goldToken.address}`)
}

deploy()