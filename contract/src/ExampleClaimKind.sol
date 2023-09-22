// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import "./IClaimKind.sol";
import "./Router.sol";

contract ExampleClaimKind is IClaimKind {
    uint8 constant UNDEFINED_STATUS_CODE = 2;
    uint8 constant NO_BLESSER_STATUS_CODE = 3;
    uint8 constant EXPIRED_STATUS_CODE = 4;

    Router router;

    struct Claim {
        uint248 data;
        uint8 statusCode;
    }

    Claim[] claims;

    function depositClaim(uint256[] calldata args, uint256 poolId) public returns (uint32, uint256, uint256) {
        require(args.length == 3);

        (uint32 position, uint256 batchId) = router.addClaims(1, poolId);
        uint248 data = uint248(
            uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(args)), poolId, position - 1, batchId)))
        );
        Claim memory claim = Claim(data, UNDEFINED_STATUS_CODE);
        claims.push(claim);

        return (position - 1, claims.length - 1, batchId);
    }

    function status(uint256 claimId) public view returns (uint8) {
        return claims[claimId].statusCode;
    }

    function forceFinalize(uint256 claimId, uint256[] calldata args, uint256 poolId, uint32 position, uint256 batchId)
        public
    {
        Claim memory claim = claims[claimId];
        uint248 data =
            uint248(uint256(keccak256(abi.encodePacked(keccak256(abi.encodePacked(args)), poolId, position, batchId))));
        require(claim.data == data);
        bool flag = (args[0] + args[1] == args[2]);
        if (flag) {
            claim.statusCode = 1;
        } else {
            claim.statusCode = 0;
        }
        claims[claimId] = claim;
    }

    function slash(
        uint256 claimId,
        uint256[] calldata blessings,
        uint256 poolId,
        uint256 advice,
        uint32 position,
        uint256 batchId
    ) public {
        Claim memory claim = claims[claimId];
        require(claim.statusCode < 2);

        uint248 data = uint248(uint256(keccak256(abi.encodePacked(advice, poolId, position, batchId))));

        require(claim.data == data);
        router.slash(poolId, blessings, position, claim.statusCode == 1, payable(msg.sender));
    }

    function finalize(
        uint256 claimId,
        uint256[] calldata blessings,
        uint256 poolId,
        uint256 advice,
        uint32 position,
        uint256 batchId
    ) public {
        Claim memory claim = claims[claimId];
        require(claim.statusCode == 2);

        uint248 data = uint248(uint256(keccak256(abi.encodePacked(advice, poolId, position, batchId))));

        require(claim.data == data);
        claims[claimId].statusCode = router.check(poolId, blessings, position, batchId);
    }
}
