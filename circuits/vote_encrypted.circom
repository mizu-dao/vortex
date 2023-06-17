pragma circom 2.1.5;

include "./multisig.circom";
include "./merkle.circom";
include "./encrypt_vote.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template VoteEncrypted(DEPTH, PUBKEYS_MAX_AMOUNT){
    // Public inputs
    signal input propId; 
    signal input encryptedVoteC[2];
    signal input encryptedVoteK[2];
    signal input P[2];

    // Private inputs
    signal input secret;

    signal input pathElements[DEPTH];
    signal input pathSelectors[DEPTH];

    signal input votePower;

    signal input pubkeys[PUBKEYS_MAX_AMOUNT][2];
    signal input sigR[PUBKEYS_MAX_AMOUNT][2];
    signal input sigS[PUBKEYS_MAX_AMOUNT];
    signal input threshold;

    signal input k;
    signal input vote;

    // Outputs
    signal output root;
    signal output nullifier;

    IsValidVoteEncryption()(P <== P, C <== encryptedVoteC, K <== encryptedVoteK, k <== k, vote <== vote, votePower <== votePower);

    component multisig = Multisig(PUBKEYS_MAX_AMOUNT);
    multisig.m <== vote + 2 * propId;
    multisig.s <== sigS;
    multisig.R <== sigR;
    multisig.P <== pubkeys;
    multisig.threshold <== threshold;

    signal leaf <== Poseidon(2)([multisig.pubkeysHash, threshold]);
    root <== MerkleTree(DEPTH)(leaf, pathElements, pathSelectors);

    signal id <== propId * (2**20) - 1;

    nullifier <== Poseidon(2)([secret, id]);
}

component main { public [propId, encryptedVoteC, encryptedVoteK, P] } = VoteEncrypted(20, 7);