import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//https://docs.chain.link/ccip/supported-networks
const VoterCCModule = buildModule("VoterCCARB", (m) => {
  const erc20 = m.contract("ERC20Token", ["HonoTest", "HONO"]);

  const ccip = m.contract("VoterCC",["0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165"]);
  const voter = m.contract("Voter", [erc20, ccip, true]);
  const storage = m.contract("VoteStorage", [voter]);
  m.call(voter, "ChangeVoteStorage", [storage]);
  return { ccip, voter ,storage};
});

export default VoterCCModule;
