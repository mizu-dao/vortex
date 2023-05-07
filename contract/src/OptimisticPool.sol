// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;





contract ProvingPool {

    struct Blessing{
        address blesser;
        uint16 amount; // uint8 is not enough, because 256 doesn't fit
        uint256 bitfield;
    }

    struct Claim{
        uint32 kind;
        uint224 claim;
    }

    struct ClaimBatch{
        mapping(uint => Claim) claims;
        uint head;
    }

    uint constant RING_SIZE = 69; // claim batches will start getting overwritten after circling for RINGSIZE time
    uint constant BATCH_FINALIZATION_TIME = 12 hours; 
    // longer batch finalization <=> more gas savings, but even small ones give significant advantage, and on a long run should not matter too much
    // also, gas savings are significant even for short batches; and UX is much better if they are frequent
    uint constant BLESSING_TIME = 1 hours; // can be relatively short
    uint constant CHALLENGE_TIME = 7 hours;
    // this is scary - if an attacker can censor the network for 7 hours, they will create a wrong proof
    // however, it is roughly comparable with level of security provided by Arbitrum - they need 7 days for multiple challenges

    mapping(uint => ClaimBatch) private claimRingQueue; // this will keep RINGSIZE amount of batches of length at most 256

    mapping(uint => Blessing) private blesserQueue; // 

    mapping(uint => address) private kindQueue; // list of checker contracts, appendable by anyone
    



    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}


// We have the following append-only structures: blesser queue, claim queue, claim_type queue
// Blesser queue is (uint -> Blessing)
// Blessing = (blesser: address, bless_amount: uint8, bitfield: uint256) <-- bless amount should be counted but we are lazy :)
// Notice that blesser, bless_amount are packed, because address is 160 bit

// Claim_type queue is an append-only list of addresses. It is appendable by any1. [CHECK: no attacks stemming from shitty claim checker contracts that are
// trying to do some funky stuff.] <-- that means that we can permissionlessly add new claim types (and our subchecks of the tree proof can be deposited to
// the proving pool). The cost is external call in case of the check, so we basically don't care.

// !! we also lose the ability to slash for incorrect 

// Claim queue is an interesting thing; need to understand how to lay it out.
// Let's try to write down what it needs to do.

// claim(...) function should take integer value i and some calldata, merkle-keccak it and put the resulting hash into claim stack

// existing claims are in batches
// 