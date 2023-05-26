pragma circom 2.1.5;

include "./lib/poseidon.circom";
include "./lib/bitify.circom";
include "./lib/mux1.circom";

template MerkleTree(D) {
    signal input root;
    signal input selectors[D];
    signal input path_wtns[D][2];
    signal output leaf;


    // ensure that the each selector is a bit - switcher component doesn't do it

    for (var i = 0; i < D; i++){
        selectors[i]*selectors[i] === selectors[i];
    }

    // compute the path - 0-th term is a root, and others are chosen from path_wtns according to selectors

    signal path[D+1];
    path[0] <== root; // compiler will optimize this out anyways, no big deal
    for (var i = 0; i < D; i++){
        path[i+1] <== Mux1()(s <== selectors[i], c <== path_wtns[i]);
    }

    // ensure that each intermediate vertex in a path is a hash of the path witness

    component hashes[D];
    for (var i = 0; i < D; i++){
        hashes[i] = Poseidon(2);
        hashes[i].inputs <== path_wtns[i];
        path[i] === hashes[i].out;
    }

    // output the leaf

    leaf <== path[D];

}


component main {public[root]} = MerkleTree(20);