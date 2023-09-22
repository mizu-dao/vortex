// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

interface ClaimKind {
    function depositClaim(uint256[] calldata args, uint256 poolId) external returns (uint32, uint256, uint256);

    function status(uint256 claimId) external view returns (uint8);

    function forceFinalize(uint256 claimId, uint256[] calldata args, uint256 poolId, uint32 position, uint256 batchId)
        external;

    function slash(
        uint256 claimId,
        uint256[] calldata blessings,
        uint256 poolId,
        uint256 advice,
        uint32 position,
        uint256 batchId
    ) external;

    function finalize(
        uint256 claimId,
        uint256[] calldata blessings,
        uint256 poolId,
        uint256 advice,
        uint32 position,
        uint256 batchId
    ) external;
}
