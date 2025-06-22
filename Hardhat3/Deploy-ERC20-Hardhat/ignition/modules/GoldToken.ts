import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("GoldTokenModule", (m) => {
  const goldToken = m.contract("GoldToken", [1000]);
  return { goldToken };
});
