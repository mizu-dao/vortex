pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/babyjub.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

// Checks validity of Schnorr Signature; does not check that P or R live in a subgroup.
template SchnorrSignature() {
    // Schnorr signature is a pair (s, R) satisfying sG = R + Pubkey * Hash(R, Pubkey, m)

    signal input s;
    signal input m;
    signal input R[2];
    signal input P[2]; 

    signal output out;

    BabyCheck()(P[0], P[1]);
    BabyCheck()(R[0], R[1]);

    signal sG[2];
    (sG[0], sG[1]) <== BabyPbk()(s);

    signal hashRPm <== Poseidon(5)([R[0], R[1], P[0], P[1], m]);
    signal hashBits[254] <== Num2Bits_strict()(hashRPm);
    
    component pkRescaled = EscalarMulAny(128);
    for (var i = 0; i < 128; i++) {
        pkRescaled.e[i] <== hashBits[i];
    }
    pkRescaled.p <== P;

    signal (RPlusPkRescaledX, RPlusPkRescaledY) <== BabyAdd()(R[0], R[1], pkRescaled.out[0], pkRescaled.out[1]);

    signal xcheck <== IsEqual()([sG[0], RPlusPkRescaledX]);
    signal ycheck <== IsEqual()([sG[1], RPlusPkRescaledY]);

    out <== xcheck * ycheck;
}
