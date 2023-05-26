pragma circom 2.1.5;

include "./lib/poseidon.circom";
include "./merkle.circom";


// this defines the container for the data in the leaves of the Merkle tree
// layout is as follows: LEAF = HASH(VOTE_POWER, REGISTRATION_DATA)
// VOTE_POWER is unconstrained, because it MUST be validated on the level of smart contract
// REGISTRATION_DATA = HASH(REGISTRATION_DATA_ROOT, SECRET)
// REGISTRATION_DATA_ROOT is supplied by the user, and is only used to check their intent to vote
// REGISTRATION_DATA_ROOT is itself a Merkle tree, with leaves containing Hash(pubkeys_hash, threshold, prop_id}
// this can be optimized in a lot of places; but probably not worth the potential of making a mistake

template ParseContainer(DEPTH) {

    signal input vote_power;
    signal input pubkeys_hash;
    signal input threshold;
    signal input prop_id;
    
    signal input secret;
    signal input registration_data_root;
    signal input path_wtns[DEPTH][2];
    signal input selectors[DEPTH];


    // compute Merkle leaf of the registration_data_root
    signal registration_data_leaf1 <== MerkleTree(DEPTH)(root <== registration_data_root, selectors <== selectors, path_wtns <== path_wtns);
    // unpack it to pubkeys_hash, threshold, prop_id
    signal registration_data_leaf2 <== Poseidon(3)([pubkeys_hash, threshold, prop_id]);
    //ensure we have unpacked the correct thing
    registration_data_leaf1 === registration_data_leaf2;


    signal registration_data <== Poseidon(2)([registration_data_root, secret]);
    
    //output container
    signal output container <== Poseidon(2)([vote_power, registration_data]);
}