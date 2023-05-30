pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template MerkleTree(DEPTH) {
    signal input root;
    signal input selectors[DEPTH];
    signal input path_wtns[DEPTH][2];
    signal output leaf;

    // ensure that the each selector is a bit - switcher component doesn't do it

    for (var i = 0; i < DEPTH; i++){
        selectors[i]*selectors[i] === selectors[i];
    }

    // compute the path - 0-th term is a root, and others are chosen from path_wtns according to selectors

    signal path[DEPTH+1];
    path[0] <== root; // compiler will optimize this out anyways, no big deal
    for (var i = 0; i < DEPTH; i++){
        path[i+1] <== Mux1()(s <== selectors[i], c <== path_wtns[i]);
    }

    // ensure that each intermediate vertex in a path is a hash of the path witness

    component hashes[DEPTH];
    for (var i = 0; i < DEPTH; i++){
        hashes[i] = Poseidon(2);
        hashes[i].inputs <== path_wtns[i];
        path[i] === hashes[i].out;
    }

    // output the leaf

    leaf <== path[DEPTH];

}