import { describe, it } from "node:test";
import { network } from "hardhat";
import { deployProxy } from "../scripts/deployProxy.js";
import { upgradeProxy } from "../scripts/upgradeProxy.js";
import assert from "node:assert/strict";
import BoxV2 from "../ignition/modules/BoxV2.js";


describe("Proxy", async function () {

  // 1. Initialize connection
  const { viem, ignition, networkHelpers } = await network.connect();

  // 2. Fixture deploying proxy
  async function deployProxyFixture(){
    const proxy = await deployProxy(viem, ignition);
    return proxy
  }

  it("should deploy the proxy and return BoxV1 version", async function () {

    // Deploy proxy
    const _proxy = await networkHelpers.loadFixture(deployProxyFixture);

    // Get proxy contract
    const proxy =  await viem.getContractAt("BoxV1", _proxy.address)

    // Read version
    const version = await proxy.read.version()
    
    assert.equal(version, 1n, "Version should be 1");
  });

  it("value variable should be equal to 0", async function () {

    // Deploy proxy
    const _proxy = await networkHelpers.loadFixture(deployProxyFixture);

    // Get proxy contract
    const proxy =  await viem.getContractAt("BoxV1", _proxy.address)

    // Read value
    const value = await proxy.read.getValue()

    assert.equal(value, 0n, "value should be 0")
  })

  it("should update proxy to point to BoxV2 and return appropriate version", async function () {

     // Deploy proxy
     const _proxy = await networkHelpers.loadFixture(deployProxyFixture);

     // Update proxy to point to BoxV2
     await upgradeProxy(viem, ignition, BoxV2, _proxy.address)

    // Get proxy contract
    const proxy =  await viem.getContractAt("BoxV2", _proxy.address)

    // Read version
    const version = await proxy.read.version()
    
    assert.equal(version, 2n, "Version should be 2");     
  })
});
