// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface Poseidon {
    function poseidon(uint256[2] calldata) external view returns (uint256);
}

// address constant POSEIDON_HASHER_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

contract PoseidonClaimKind {
    uint256[] values;

    uint256 claim;

    function setValues(uint256 n) public {
        for (uint256 i = 0; i < n; i++) {
            values.push(i);
        }
    }

    function getValue(uint256 index) public view returns (uint256) {
        return values[index];
    }

    function getLength() public view returns (uint256) {
        return values.length;
    }

    // function hash(uint256 a, uint256 b) public view returns (uint256) {
    //     return (Poseidon(POSEIDON_HASHER_ADDRESS).poseidon([a, b]));
    // }

    function depositClaim(uint256[] calldata array) public returns (uint256) {
        require(array.length ** 2 <= values.length && (array.length + 1) ** 2 > values.length);

        uint256[] memory vertices = new uint[](array.length - 1);
        uint256 i;

        for (; i < array.length / 2; i++) {
            vertices[i] = uint256(keccak256(abi.encodePacked(array[2 * i], array[2 * i + 1])));
        }

        if (array.length != 2 * i) {
            vertices[i] = uint256(keccak256(abi.encodePacked(array[2 * i], vertices[0])));
            i++;
        }

        for (; i < array.length - 1; i++) {
            vertices[i] =
                uint256(keccak256(abi.encodePacked(vertices[2 * i - array.length], vertices[2 * i + 1 - array.length])));
        }

        claim = vertices[array.length - 2];

        return vertices[array.length - 2];
    }
}
