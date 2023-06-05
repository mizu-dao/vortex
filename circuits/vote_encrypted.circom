pragma circom 2.1.5;

include "./multisig.circom";
include "./merkle.circom";
include "./encrypt_vote.circom";
include "./registration_utils.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template VoteEncrypted(VOTER_TREE_DEPTH, REGISTRATION_TREE_DEPTH, PUBKEYS_MAX_AMOUNT){

    //public inputs
    
    signal input merkle_root; // this will be a public input, supplied by the user; it is not constrained by a contract
                              // - but votes to different Merkle roots go into different buckets
    signal input prop_id;   // id of the proposal
    signal input encrypted_vote_C[2]; // encrypted vote
    signal input encrypted_vote_K[2]; // encrypted vote
    signal input P[2]; // public key of decryption authority committee, ASSUMED TO BE A VALID POINT

    //private inputs
    
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

    signal input is_restricted_by_prop; // bool value indicating whether prop_id should be given or default value -1

    // if is_restricted_by_prop == 0, then container.prop_id == -1, container.vote == 0
    // if is_restricted_by_prop == 1, then container.prop_id == prop_id, container.vote == vote

    is_restricted_by_prop*is_restricted_by_prop === is_restricted_by_prop;

    signal input k;
    signal input vote;

    IsValidVoteEncryption()(P <== P, C <== encrypted_vote_C, K <== encrypted_vote_K, k <== k, vote <== vote, vote_power <== vote_power);

    component multisig = Multisig(PUBKEYS_MAX_AMOUNT);
    multisig.m <== vote + 2*prop_id;
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
    parse_container.prop_id <== (prop_id+1)*is_restricted_by_prop - 1; 
    parse_container.threshold <== threshold;
    parse_container.pubkeys_hash <== multisig.pubkeys_hash;
    parse_container.secret <== secret;
    parse_container.vote <== vote*is_restricted_by_prop; 

    parse_container.container === container;

    signal id <== prop_id * (2**20) - 1; // subtracting 1 to prevent collision with fallback scheme

    signal output nullifier <== Poseidon(2)([secret, id]);
}



component main {public[merkle_root, prop_id, encrypted_vote_C, encrypted_vote_K, P]} = VoteEncrypted(20, 4, 7);