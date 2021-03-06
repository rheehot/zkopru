pragma solidity >= 0.6.0;

import "../libraries/Types.sol";
import { Pairing } from "../libraries/Pairing.sol";
import { SNARKsVerifier } from "../libraries/SNARKs.sol";
import { Configurated } from "./Configurated.sol";

import { SMT254 } from "../libraries/SMT.sol";
import { OPRU, SplitRollUp } from "../libraries/Tree.sol";

struct RollUpProofs {
    SplitRollUp[] ofUTXORollUp;
    SMT254.OPRU[] ofNullifierRollUp;
    SplitRollUp[] ofWithdrawalRollUp;
    mapping(uint8=>mapping(uint=>address)) permittedTo;
}

contract Layer2 is Configurated {
    /** State of the layer2 blockchain is maintained by the optimistic roll up */
    Blockchain chain;

    /** SNARKs verifying keys assigned by the setup wizard for each tx type */
    mapping(bytes32=>SNARKsVerifier.VerifyingKey) vks;

    /** Addresses allowed to migrate from. Setup wizard manages the list */
    mapping(address=>bool) public allowedMigrants;

    /** Roll up proofs for challenge */
    RollUpProofs proof;

    function genesis() public view returns (bytes32) {
        return chain.genesis;
    }

    function latest() public view returns (bytes32) {
        return chain.latest;
    }

    function proposedBlocks() public view returns (uint256) {
        return chain.proposedBlocks;
    }

    function parentOf(bytes32 header) public view returns (bytes32) {
        return chain.parentOf[header];
    }

    function utxoRootOf(bytes32 header) public view returns (uint256) {
        return chain.utxoRootOf[header];
    }

    function withdrawalRootOf(bytes32 header) public view returns (uint256) {
        return chain.withdrawalRootOf[header];
    }

    function finalizedUTXORoots(bytes32 utxoRoot) public view returns (bool) {
        return chain.finalizedUTXORoots[uint(utxoRoot)];
    }

    function proposers(address addr) public view returns (uint stake, uint reward, uint exitAllowance) {
        Proposer memory proposer = chain.proposers[addr];
        stake = proposer.stake;
        reward = proposer.reward;
        exitAllowance = proposer.exitAllowance;
    }

    function proposals(bytes32 proposalId) public view returns (bytes32 header, uint challengeDue, bool slashed) {
        Proposal memory proposal = chain.proposals[proposalId];
        header = proposal.headerHash;
        challengeDue = proposal.challengeDue;
        slashed = proposal.slashed;
    }

    function stagedDeposits() public view returns (bytes32 merged, uint fee) {
        MassDeposit memory massDeposit = chain.stagedDeposits;
        merged = massDeposit.merged;
        fee = massDeposit.fee;
    }

    function stagedSize() public view returns (uint) {
        return chain.stagedSize;
    }

    function massDepositId() public view returns (uint) {
        return chain.massDepositId;
    }

    function committedDeposits(bytes32 massDepositHash) public view returns (uint) {
        return chain.committedDeposits[massDepositHash];
    }

    function withdrawn(bytes32 leaf) public view returns (bool) {
        return chain.withdrawn[leaf];
    }

    function migrations(bytes32 migrationHash) public view returns (bool) {
        return chain.migrations[migrationHash];
    }

    function getVk(uint8 numOfInputs, uint8 numOfOutputs) public view returns (
        uint[2] memory alfa1,
        uint[2][2] memory beta2,
        uint[2][2] memory gamma2,
        uint[2][2] memory delta2,
        uint[2][] memory ic
    ) {
        bytes32 txSig = Types.getSNARKsSignature(numOfInputs, numOfOutputs);
        SNARKsVerifier.VerifyingKey memory vk = vks[txSig];
        alfa1[0] = vk.alfa1.X;
        alfa1[1] = vk.alfa1.Y;
        beta2[0] = vk.beta2.X;
        beta2[1] = vk.beta2.Y;
        gamma2[0] = vk.gamma2.X;
        gamma2[1] = vk.gamma2.Y;
        delta2[0] = vk.delta2.X;
        delta2[1] = vk.delta2.Y;
        ic = new uint[2][](vk.ic.length);
        for(uint i = 0; i < vk.ic.length; i++) {
            ic[i] = [vk.ic[i].X, vk.ic[i].Y];
        }
    }
}
