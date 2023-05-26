pragma circom 2.1.5;

include "./multisig.circom";
include "./merkle.circom";
include "./registration_utils.circom";
include "./lib/comparators.circom";
include "./lib/bitify.circom";



template VoteFallback(VOTER_TREE_DEPTH, REGISTRATION_TREE_DEPTH, PUBKEYS_MAX_AMOUNT){

    //public inputs
    
    signal input merkle_root; // this will be a public input, supplied by the user; it is not constrained by a contract
                              // - but votes to different Merkle roots go into different buckets
    signal input prop_id;   // id of the proposal
    signal input vote; // 0, 1 or 2

    //private inputs
    
    signal input noun_id; // noun_id is a value from 0 to amount of Nouns on user account; in a fallback scheme they vote separately
    signal input secret;

    signal input voter_path_wtns[VOTER_TREE_DEPTH][2]; // Merkle path to the container
    signal input voter_selectors[VOTER_TREE_DEPTH];

    signal input registration_data_root;
    signal input reg_path_wtns[REGISTRATION_TREE_DEPTH][2];
    signal input reg_selectors[REGISTRATION_TREE_DEPTH];

    signal input vote_power;
    signal input pubkeys[PUBKEYS_MAX_AMOUNT][2];
    signal input sigs_R[PUBKEYS_MAX_AMOUNT][2];
    signal input sigs_s[PUBKEYS_MAX_AMOUNT];
    signal input threshold;

    component multisig = Multisig(PUBKEYS_MAX_AMOUNT);
    multisig.m <== vote + 3*prop_id;
    multisig.s <== sigs_s;
    multisig.R <== sigs_R;
    multisig.P <== pubkeys;
    multisig.threshold <== threshold;
    
    signal container <== MerkleTree(VOTER_TREE_DEPTH)(root <== merkle_root, selectors <== voter_selectors, path_wtns <== voter_path_wtns);

    component parse_container = ParseContainer(REGISTRATION_TREE_DEPTH);
    
    parse_container.vote_power <== vote_power;
    parse_container.registration_data_root <== registration_data_root;
    parse_container.path_wtns <== reg_path_wtns;
    parse_container.selectors <== reg_selectors;
    parse_container.prop_id <== prop_id;
    parse_container.threshold <== threshold;
    parse_container.pubkeys_hash <== multisig.pubkeys_hash;
    parse_container.secret <== secret;

    parse_container.container === container;

    _ <== Num2Bits(20)(noun_id); //constrain noun_id to be smol
    component lt = LessThan(20);
    lt.in <== [noun_id, vote_power];
    lt.out === 1; // ensure that noun_id < vote_power; vote_power is assumed to be already smol

    signal id <== noun_id * (2**20) + prop_id;

    signal output nullifier <== Poseidon(2)([id, secret]);
}



component main {public[merkle_root, prop_id, vote]} = VoteFallback(20, 4, 7);