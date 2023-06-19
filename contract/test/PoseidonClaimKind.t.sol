// SPDX-License-Identifier: Apache-2.0 OR MIT
// pragma solidity ^0.8.17;

// import "forge-std/Test.sol";
// import "../src/PoseidonClaimKind.sol";

// contract MyTest is Test {
//     PoseidonClaimKind public poseidonClaimKind;

//     function setUp() public {
//         poseidonClaimKind = new PoseidonClaimKind();
//     }

//     function testFirst() public {
//         poseidonClaimKind.setValues(25);
//         uint256[] memory array = new uint256[](5);
//         array[0] = 1;
//         array[1] = 2;
//         array[2] = 3;
//         array[3] = 4;
//         array[4] = 5;
//         uint256 root = poseidonClaimKind.depositClaim(array);

//         assertEq(root, keccakHash(keccakHash(3, 4), keccakHash(5, keccakHash(1, 2))));
//     }

//     function keccakHash(uint256 a, uint256 b) public pure returns (uint256) {
//         return uint256(keccak256(abi.encodePacked(a, b)));
//     }
// }
