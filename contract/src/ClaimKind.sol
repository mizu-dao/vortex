// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

abstract contract ClaimKind {
    address router;

    uint256[] claims;

    function depositClaim(uint256[] calldata args, uint256 poolId) external virtual returns (uint256);

    function status(uint256 claimId) public view virtual;

    function check(uint256 claimId) public view virtual;

    function finalize(uint256 claimId) external virtual;
}
