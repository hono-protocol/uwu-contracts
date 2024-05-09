import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//https://docs.chain.link/ccip/supported-networks
const VoterCCModule = buildModule("VoterCC", (m) => {
  const erc20 = m.contract("ERC20Token", ["HonoTest", "HONO"]);

  const ccip = m.contract("VoterCC",["0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93"]);
  const voter = m.contract("Voter", [erc20, ccip, true]);
  const storage = m.contract("VoteStorage", [voter]);
  m.call(voter, "ChangeVoteStorage", [storage]);
  return { ccip, voter ,storage};
});

export default VoterCCModule;
