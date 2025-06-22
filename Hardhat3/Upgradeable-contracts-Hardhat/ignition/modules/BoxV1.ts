import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("BoxV1Module", (m) => {
  const boxV1 = m.contract("BoxV1");
  return { boxV1 };
});
