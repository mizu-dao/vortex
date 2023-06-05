pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "./merkle.circom";

// This defines the container for the data in the leaves of the Merkle tree
// layout is as follows: LEAF = HASH(VOTE_POWER, REGISTRATION_DATA)
// VOTE_POWER is unconstrained, because it MUST be validated on the level of smart contract
// REGISTRATION_DATA = HASH(REGISTRATION_DATA_ROOT, SECRET)
// REGISTRATION_DATA_ROOT is supplied by the user, and is only used to check their intent to vote
// REGISTRATION_DATA_ROOT is itself a Merkle tree, with leaves containing Hash(pubkeys_hash, threshold, prop_id, vote)
// prop_id = -1 is a default value, in this case vote should be equal to 0

template ParseContainer(DEPTH) {
    signal input vote_power;
    signal input pubkeys_hash;
    signal input threshold;
    signal input prop_id;
    signal input vote;
    signal input secret;
    signal input path_wtns[DEPTH];
    signal input selectors[DEPTH];

    signal output registration_data_root;
    signal output container;

    signal registration_data_leaf <== Poseidon(4)([pubkeys_hash, threshold, prop_id, vote]);

    registration_data_root <== MerkleTree(DEPTH)(registration_data_leaf, selectors, path_wtns);

    signal registration_data <== Poseidon(2)([registration_data_root, secret]);
    container <== Poseidon(2)([vote_power, registration_data]);
}