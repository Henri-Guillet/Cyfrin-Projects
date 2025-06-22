import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

export default buildModule("ProxyModule", (m) => {
  const boxV1 = m.contract("BoxV1")
  // const proxy = m.contract("ERC1967Proxy", [boxV1, ""]);
  return { boxV1 };
});
