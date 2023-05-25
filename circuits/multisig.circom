pragma circom 2.1.5;

include "./signature.circom";
include "./lib/comparators.circom";
include "./lib/poseidon.circom";
include "./lib/binsum.circom";

/// checks that at least T of N signatures are valid
template MultiSig(N, T){
    signal input pubkeys_hash;
    signal input m;
    signal input s[N];
    signal input R[N][2];
    signal input P[N][2];

    component pubkeys_hasher = Poseidon(N);
    for (var i = 0; i < N; i++){
        pubkeys_hasher.inputs[i] <== P[i][0];
        }

    pubkeys_hash === pubkeys_hasher.out;

    component sigs[N];
    
    for (var i = 0; i < N; i++){
        sigs[i] = SchnorrSignature();
        sigs[i].s <== s[i];
        sigs[i].R <== R[i];
        sigs[i].m <== m;
        sigs[i].P <== P[i];
    }

    var acc = 0;

    for (var i = 0; i < N; i++){
        acc += sigs[i].out;
    }

    var logN = nbits(N)+1;
    signal ans <== GreaterEqThan(logN)([acc, T]);
    ans === 1;
}

component main {public [pubkeys_hash, m]} = MultiSig(7, 4);