// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

contract ProvingPool {
    struct Blessing {
        address blesser;
        uint256 bitfield;
    }

    struct Claim {
        uint32 kind;
        uint224 claim;
    }

    struct ClaimBatch {
        mapping(uint256 => Claim) claims;
        mapping(uint256 => Blessing) blessings;
        uint256 currentClaim;
        uint256 currentBlessing;
    }

    struct BatchRing {
        mapping(uint256 => ClaimBatch) batches;
        uint256 currentBatch;
    }

    mapping(uint256 => ClaimBatch) private claimRingQueue;

    mapping(uint256 => address) private blesserQueue;

    mapping(uint256 => address) private kindQueue;

    function registerKind() public {}
}
