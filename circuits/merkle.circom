pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template MerkleTree(DEPTH) {
    signal input leaf;
    signal input pathElements[DEPTH];
    signal input pathSelectors[DEPTH];

    signal output root;

    signal mux[DEPTH][2];
    signal levelHashes[DEPTH + 1];
    
    levelHashes[0] <== leaf;
    for (var i = 0; i < DEPTH; i++) {
        pathSelectors[i] * (pathSelectors[i] - 1) === 0;

        mux[i] <== MultiMux1(2)(
            [
                [levelHashes[i], pathElements[i]], 
                [pathElements[i], levelHashes[i]]
            ], 
            pathSelectors[i]
        );

        levelHashes[i + 1] <== Poseidon(2)([mux[i][0], mux[i][1]]);
    }

    root <== levelHashes[DEPTH];
}