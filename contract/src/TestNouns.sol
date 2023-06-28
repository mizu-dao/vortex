// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract Nouns {
    uint256 private total_supply;
    

    function mockTotalSupply(uint256 _total_supply) external {
        total_supply = _total_supply;
    }

    function tokenByIndex(uint256 id) external view returns (uint256){
        require(id<total_supply);
        return id;
    }

    function totalSupply() external view returns (uint256) {
        return total_supply;
    }
}