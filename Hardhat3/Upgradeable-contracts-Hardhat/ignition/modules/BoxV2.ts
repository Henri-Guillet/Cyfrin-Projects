import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("BoxV2Module", (m) => {
  const boxV2 = m.contract("BoxV2");
  return { boxV2 };
});
