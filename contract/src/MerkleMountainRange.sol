// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract MerkleMountainRange {

    struct enumeratedCap{
        uint8 cap_depth;
        uint248 cap_hash;
    }

    struct merklePathEntry{
        uint248 element;
        bool selector;
    }

    uint8 caps_length;
    mapping(uint8 => enumeratedCap) caps;

    function push(uint248 update) internal {
        
        uint8 _caps_length = caps_length;

        if (_caps_length == 0) {
            caps_length == 1;
            caps[0] = enumeratedCap(0, update);
            return;
        }

        enumeratedCap memory _update = enumeratedCap(0, update);
        enumeratedCap memory cap;
        _caps_length -= 1;
        while(true){
            cap = caps[_caps_length];
            if (cap.cap_depth == _update.cap_depth){
                _update = enumeratedCap(_update.cap_depth + 1, uint248(uint256((keccak256(abi.encodePacked(cap.cap_hash, _update.cap_hash))))));
                if (_caps_length == 0){
                    caps[0] = _update;
                    caps_length = 1;
                    return;
                }
                _caps_length -= 1;
            } else {
                caps[_caps_length] = _update;
                caps_length = _caps_length + 2;
                return;
            } 
            
        }
    }

    function validate(uint256 id, uint248 leaf, uint248[] calldata path) internal view {
        uint256 length = path.length;
        uint8 _caps_length = caps_length;
        uint248 l;
        uint248 r;
        for(uint256 i = 0; i < _caps_length ; i++) {
            
            enumeratedCap memory tmp = caps[uint8(i)];
            uint256 offset = 1 << tmp.cap_depth;
            if (id >= offset){
                id -= offset;
            } else {
                require(length == tmp.cap_depth, "path has incorrect length");
                l = leaf;
                for (uint256 j = 0; j < path.length; j++){
                    r = path[j];
                    if ( 1 == ((id<<j) & 1) ) {
                        (l, r) = (r, l);
                    }
                    l = uint248(uint256((keccak256(abi.encodePacked(l, r)))));
                }
                require(l == tmp.cap_hash);
                return;
            }

            require(false, "id out of range");
        }
    }

}
