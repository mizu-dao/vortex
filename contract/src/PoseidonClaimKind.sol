// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface Nouns {
    function tokenByIndex(uint256) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface Poseidon {
    function poseidon(uint256[2] calldata) external view returns (uint256);
}

interface OptimisticPool{
    function registerClaimKind(address) external returns (uint256); // registers address as a ClaimKind, returns its id
    function depositClaim(uint256) external returns (uint256); // deposits uint256 as a claim root of a claim kind msg.sender,
                                                            //reverts if the claim kind is not registered; returns claim id
}


// this: 0x809d550fca64d94Bd9F66E60752A544199cfAC3D
address constant OPTIMISTIC_POOL_ADDRESS = address(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);
address constant POSEIDON_HASHER_ADDRESS = address(0x5FbDB2315678afecb367f032d93F642f64180aa3);
address constant NOUNS_TOKEN_ADDRESS = address(0x5FC8d32690cc91D4c39d9d3abcBD16989F875707);

contract PoseidonClaimKind {


    function getLeavesAmount() private view returns (uint) {
        return Nouns(NOUNS_TOKEN_ADDRESS).totalSupply();
    }


    function log2(uint256 x) private pure returns (uint) {
        assert (x > 0);
        x -= 1;
        uint acc = 0;
        if (x >= 2**128) {
            acc += 128;
            x >>= 128;
        }
        if (x >= 2**64) {
            acc += 64;
            x >>= 64;
        }
        if (x >= 2**32) {
            acc += 32;
            x >>= 32;
        }
        if (x >= 2**16) {
            acc += 16;
            x >>= 16;
        }        
        if (x >= 2**8) {
            acc += 8;
            x >>= 8;
        }
        if (x >= 2**4) {
            acc += 4;
            x >>= 4;
        }
        if (x >= 2**2) {
            acc += 2;
            x >>= 2;
        }
        if (x >= 2) {
            acc += 1;
            x >>= 1;
        }
        return acc+1;
    }

    function poseidonHash(uint256 a, uint256 b) private view returns (uint256) {
        return (Poseidon(POSEIDON_HASHER_ADDRESS).poseidon([a, b]));
    }

    function computeSubroot(uint256 subroot_id) public view returns (uint256){
            uint bits = log2(getLeavesAmount());
            uint len = 2**(bits/2);
            require(subroot_id < 2**((bits+1)/2));
            uint256 offset = subroot_id*len;
            uint256[] memory arr = new uint256[](len - 1);
            uint i = 0;

            for (; i<len/2; i++){
                arr[i] = poseidonHash(loadRegistrationData(offset+2*i), loadRegistrationData(offset+2*i+1));
            } 
            
            for (; i < arr.length; i++){
             //   if (i<(arr.length-10)){arr[i]=0;}else{
                arr[i] = poseidonHash(arr[2*i-len], arr[2*i+1-len]);//}
            }

            return arr[arr.length-1];
    }
    
    // straightforwardly computing root might be larger than node RPC gas limits,
    // so we split the execution using this helper function:
    function computeRoot(uint256[] calldata poseidon_subroots) external view returns(uint256, uint256[] memory){
        uint bits = log2(getLeavesAmount());

        require(poseidon_subroots.length ==2**((bits+1)/2));

        uint256[] memory arr = new uint256[](poseidon_subroots.length - 1);
        
        uint i = 0;
        for (; i<poseidon_subroots.length/2; i++){
            arr[i] = poseidonHash(poseidon_subroots[2*i], poseidon_subroots[2*i+1]);
        } 
        for (; i < arr.length; i++){
            arr[i] = poseidonHash(arr[2*i-poseidon_subroots.length], arr[2*i+1 - poseidon_subroots.length]);
        }

        return (arr[arr.length-1], poseidon_subroots);
    }



    function depositClaim(uint256 poseidon_root, uint256[] calldata poseidon_subroots) external {
        uint bits = log2(getLeavesAmount());
        require(2**((bits+1)/2) == poseidon_subroots.length);
        OptimisticPool(OPTIMISTIC_POOL_ADDRESS).depositClaim((uint256(keccak256(abi.encodePacked(poseidon_root, poseidon_subroots))) & ~uint256(3)) + 1);
    }

    function loadRegistrationData(uint id) private view returns (uint256) {
        if (id >= Nouns(NOUNS_TOKEN_ADDRESS).totalSupply()) {
            return 0;
        }
        return Nouns(NOUNS_TOKEN_ADDRESS).tokenByIndex(id); //should be replaced by actual registration data loader
    }

    // this function will not revert only if the fraud proof is correct

    function evaluateClaim (uint256 claim, uint256 poseidon_root, uint256[] calldata poseidon_subroots, uint blame) external view {
        uint bits = log2(getLeavesAmount());
        require (2**((bits+1)/2) == poseidon_subroots.length);
        require(claim == ((uint256(keccak256(abi.encodePacked(poseidon_root, poseidon_subroots))) & ~uint256(3)) + 1 ));
        
        if (blame == poseidon_subroots.length) {
            uint256[] memory arr = new uint256[](poseidon_subroots.length - 1);
            uint i = 0;
            for (; i<poseidon_subroots.length/2; i++){
                arr[i] = poseidonHash(poseidon_subroots[2*i], poseidon_subroots[2*i+1]);
            } 
            for (; i < arr.length; i++){
                arr[i] = poseidonHash(arr[2*i-poseidon_subroots.length], arr[2*i+1 - poseidon_subroots.length]);
            }

//            return arr[arr.length-1] - poseidon_root;
            require (arr[arr.length-1] != poseidon_root);
        } else {
            uint256 len = 2**(bits/2);
            require(blame < poseidon_subroots.length);
            uint256 offset = blame*len;
            uint256[] memory arr = new uint256[](len - 1);
            uint i = 0;
            for (; i<len/2; i++){
                arr[i] = poseidonHash(loadRegistrationData(offset+2*i), loadRegistrationData(2*i+1));
            } 
            for (; i < arr.length; i++){
                arr[i] = poseidonHash(arr[2*i-len], arr[2*i+1 - len]);
            }

//            return arr[arr.length-1] - poseidon_subroots[blame];
            require(arr[arr.length-1] != poseidon_subroots[blame]);
        }
    }

}
