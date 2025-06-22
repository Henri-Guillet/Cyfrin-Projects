import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("BasicNFTModule", (m) => {
  const basicNFT = m.contract("BasicNFT");
  return { basicNFT };
});
