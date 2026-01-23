import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BeggingContractModule = buildModule("BeggingContractModule", (m) => {
  // 部署参数(合约constructor 构造函数的参数)
   // 3天 = 3 * 24 * 60 * 60 = 259200 秒
  const donationDuration  = m.getParameter("donationDuration", 259200);
  
  // 部署 BeggingContract 合约
  const beggingContract = m.contract("BeggingContract", [donationDuration]);
  
  // 返回部署结果
  return { beggingContract };
});

export default BeggingContractModule;