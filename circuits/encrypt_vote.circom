pragma circom 2.1.5;

include "../node_modules/circomlib/circuits/babyjub.circom";
include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

/// homomorphic ElGamal: we encrypt YES / NO; "abstain" votes are not supported, this can be added if needed
/// the cyphertext is a pair (C = kP + vG, K = kG), where v is a vote value; v = vote_power*vote.
/// vote = 1 for YES and = 0 for NO
/// ASSUMES P IS A VALID POINT
template IsValidVoteEncryption(){
    signal input P[2];
    signal input C[2];
    signal input K[2];
    signal input k;
    signal input vote;
    signal input votePower;

    vote === vote * vote;

    signal v <== votePower * vote;

    signal kBits[252] <== Num2Bits(252)(k);

    component kP = EscalarMulAny(252);
    kP.e <== kBits;
    kP.p <== P;

    signal vG[2];
    (vG[0], vG[1]) <== BabyPbk()(v);

    signal C2[2];
    (C2[0], C2[1]) <== BabyAdd()(kP.out[0], kP.out[1], vG[0], vG[1]);

    C === C2;

    signal kG[2];
    (kG[0], kG[1]) <== BabyPbk()(k);
    kG === K;
}