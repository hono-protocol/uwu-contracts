import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//https://docs.chain.link/ccip/supported-networks
const VoterCCModule = buildModule("VoterCC", (m) => {
  const erc20 = m.contract("ERC20Token", ["HonoTest", "HONO"]);

  const ccip = m.contract("VoterCC",[0x141fa059441E0ca23ce184B6A78bafD2A517DdE8]);
  const voter = m.contract("Voter", [erc20, ccip, true]);
  const storage = m.contract("VoteStorage", [voter]);
  voter.ChangeVoteStorage(storage);
  return { ccip, voter ,storage};
});

export default VoterCCModule;
