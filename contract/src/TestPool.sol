// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract OptimisticPool {
    uint256 private claim;
    address private claimKind;
    
    function registerClaimKind(address addr) external returns (uint256) {claimKind=addr;return 0;}
    function depositClaim(uint256 _claim) external returns (uint256){claim = _claim;}
}