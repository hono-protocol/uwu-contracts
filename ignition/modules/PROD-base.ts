import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//https://docs.chain.link/ccip/supported-networks
const VoterCCModule = buildModule("VoterCC", (m) => {
  const erc20 = m.contract("ERC20Token", ["HonoTest", "HONO"]);

  const ccip = m.contract("VoterCC",["0x881e3A65B4d4a04dD529061dd0071cf975F58bCD"]);
  const voter = m.contract("Voter", [erc20, ccip, true]);
  const storage = m.contract("VoteStorage", [voter]);
  m.call(voter, "ChangeVoteStorage", [storage]);
  m.call(ccip, "updateVoterContracts", [voter,true]);
  m.call(ccip, "updateMasterVoter", [voter]);

  return { ccip,voter ,storage};
});

export default VoterCCModule;
