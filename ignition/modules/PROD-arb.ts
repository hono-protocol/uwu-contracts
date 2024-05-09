import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
//https://docs.chain.link/ccip/supported-networks
const VoterCCModule = buildModule("VoterCCARB", (m) => {
  const erc20 = m.contract("ERC20Token", ["HonoTest", "HONO"]);

  const ccip = m.contract("VoterCC",["0x141fa059441E0ca23ce184B6A78bafD2A517DdE8"]);
  const voter = m.contract("Voter", [erc20, ccip, false]);
  const storage = m.contract("VoteStorage", [voter]);
  m.call(voter, "ChangeVoteStorage", [storage]);
  m.call(ccip, "updateVoterContracts", [voter,true]);
  m.call(ccip, "updateMasterVoter", [voter]);
  //REPLACE WITH BASE CONTRACT
  m.call(ccip, "updateRecieverCCIP", ["XXXXXXXXXXX replace with base voteCC"]);
  //REPLACE WITH BASE DESTINATION
  m.call(ccip, "updateDestinationChain", ["15971525489660198786"]);
  return { ccip, voter ,storage};
});

export default VoterCCModule;
