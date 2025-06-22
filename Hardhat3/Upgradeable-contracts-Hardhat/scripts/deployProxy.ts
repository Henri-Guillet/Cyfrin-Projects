import { encodeFunctionData, Abi} from "viem";
import { loadAbi } from "../utils/loadAbi.js"
import BoxV1 from "../ignition/modules/BoxV1.js";

export async function deployProxy(viem: any, ignition: any){
    // const { viem, ignition } = await network.connect()
    const { boxV1 } = await ignition.deploy(BoxV1)
    const boxV1Abi = loadAbi("../artifacts/contracts/BoxV1.sol/BoxV1.json") as Abi
    const init = encodeFunctionData({
        abi: boxV1Abi, 
        functionName: "initialize",
        args: []
    })
    const proxy = await viem.deployContract("ERC1967ProxyWrapper", [boxV1.address, init])
    return proxy
}
