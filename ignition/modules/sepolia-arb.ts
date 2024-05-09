import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//https://docs.chain.link/ccip/supported-networks
const VoterCCModule = buildModule("VoterCCARB", (m) => {
  const erc20 = m.contract("ERC20Token", ["HonoTest", "HONO"]);

  const ccip = m.contract("VoterCC",["0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165"]);
  const voter = m.contract("Voter", [erc20, ccip, false]);
  const storage = m.contract("VoteStorage", [voter]);
  m.call(voter, "ChangeVoteStorage", [storage]);
  m.call(ccip, "updateVoterContracts", [voter,true]);
  m.call(ccip, "updateMasterVoter", [voter]);
  //REPLACE WITH BASE CONTRACT
  m.call(ccip, "updateRecieverCCIP", ["0x20C0c5D9313F09396204A08d7feB14fB8FBB3307"]);
  //REPLACE WITH BASE DESTINATION
  m.call(ccip, "updateDestinationChain", ["10344971235874465080"]);
  return { ccip, voter ,storage};
});

export default VoterCCModule;
