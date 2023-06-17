pragma circom 2.1.5;

include "./multisig.circom";
include "./merkle.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template VoteFallback(DEPTH, PUBKEYS_MAX_AMOUNT) {
    // Public inputs
    signal input propId;
    signal input vote;

    // Private inputs
    signal input nounId;
    signal input secret;

    signal input pathElements[DEPTH];
    signal input pathSelectors[DEPTH];

    signal input vote_power;

    signal input pubkeys[PUBKEYS_MAX_AMOUNT][2];
    signal input sigR[PUBKEYS_MAX_AMOUNT][2];
    signal input sigS[PUBKEYS_MAX_AMOUNT];
    signal input threshold;

    // Outputs
    signal output root;
    signal output nullifier;

    component multisig = Multisig(PUBKEYS_MAX_AMOUNT);
    multisig.m <== vote + 2 * propId;
    multisig.s <== sigS;
    multisig.R <== sigR;
    multisig.P <== pubkeys;
    multisig.threshold <== threshold;

    signal leaf <== Poseidon(2)([multisig.pubkeysHash, threshold]);
    root <== MerkleTree(DEPTH)(leaf, pathElements, pathSelectors);

    vote === vote * vote;
    _ <== Num2Bits(20)(nounId);
    signal lt <== LessThan(20)([nounId, vote_power]);
    lt === 1;

    signal id <== propId * (2**20) + nounId;

    nullifier <== Poseidon(2)([secret, id]);
}

component main { public [propId, vote] } = VoteFallback(20, 7);