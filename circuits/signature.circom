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
    signal input m; // (hash of the) message
    signal input P[2]; // public key

    signal output out; // will be equal to 1 if the signature is valid, and 0 otherwise. 

    // question: should we get rid of the cofactor?

    BabyCheck()(P[0], P[1]); // check that P lives on curve
    BabyCheck()(R[0], R[1]); // check that R lives on curve

    signal sG[2];
    (sG[0], sG[1]) <== BabyPbk()(s); // compute s * G

    signal hash_R_P_m <== Poseidon(5)([R[0], R[1], P[0], P[1], m]);

    signal hash_bits[254] <== Num2Bits_strict()(hash_R_P_m);
    
    // we will cut off the hash to 128 bits

    component pk_rescaled = EscalarMulAny(128);

    for (var i = 0; i < 128; i++) {
        pk_rescaled.e[i] <== hash_bits[i];
    }

    pk_rescaled.p <== P;
    // and now it remains to add up and check

    component R_plus_pk_rescaled = BabyAdd();
    R_plus_pk_rescaled.x1 <== R[0];
    R_plus_pk_rescaled.y1 <== R[1];
    R_plus_pk_rescaled.x2 <== pk_rescaled.out[0];
    R_plus_pk_rescaled.y2 <== pk_rescaled.out[1];


    signal xcheck <== IsEqual()([sG[0], R_plus_pk_rescaled.xout]);
    signal ycheck <== IsEqual()([sG[1], R_plus_pk_rescaled.yout]);

    out <== xcheck * ycheck;
}
