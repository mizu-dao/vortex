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
    signal input R[2];
    signal input m;
    signal input P[2]; 

    signal output out;

    BabyCheck()(P[0], P[1]);
    BabyCheck()(R[0], R[1]);

    signal sG[2];
    (sG[0], sG[1]) <== BabyPbk()(s);

    signal hash_R_P_m <== Poseidon(5)([R[0], R[1], P[0], P[1], m]);
    signal hash_bits[254] <== Num2Bits_strict()(hash_R_P_m);
    
    component pk_rescaled = EscalarMulAny(128);
    for (var i = 0; i < 128; i++) {
        pk_rescaled.e[i] <== hash_bits[i];
    }

    pk_rescaled.p <== P;

    component R_plus_pk_rescaled = BabyAdd();
    R_plus_pk_rescaled.x1 <== R[0];
    R_plus_pk_rescaled.y1 <== R[1];
    R_plus_pk_rescaled.x2 <== pk_rescaled.out[0];
    R_plus_pk_rescaled.y2 <== pk_rescaled.out[1];

    signal xcheck <== IsEqual()([sG[0], R_plus_pk_rescaled.xout]);
    signal ycheck <== IsEqual()([sG[1], R_plus_pk_rescaled.yout]);

    out <== xcheck * ycheck;
}
