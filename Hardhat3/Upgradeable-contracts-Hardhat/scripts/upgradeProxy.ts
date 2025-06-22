const abiUpgradeToAndCall = [{
    "inputs": [
      {
        "internalType": "address",
        "name": "newImplementation",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }
    ],
    "name": "upgradeToAndCall",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  }]
  

export async function upgradeProxy(viem: any, ignition: any, impl: any, proxyAddress: string){
    const { boxV2 } = await ignition.deploy(impl)
    const [walletClient] = await viem.getWalletClients();
    await walletClient.writeContract({
        address: proxyAddress,
        abi: abiUpgradeToAndCall,
        functionName: "upgradeToAndCall",
        args: [boxV2.address, ""]
    })
}
