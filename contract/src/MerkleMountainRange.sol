// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract MerkleMountainRange {

    struct enumeratedCap{
        uint8 cap_id;
        uint248 cap_hash;
    }


    uint8 caps_length;
    mapping(uint8 => enumeratedCap) caps;

    function push(uint248 update) public {
        
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
            if (cap.cap_id == _update.cap_id){
                _update = enumeratedCap(_update.cap_id + 1, uint248(uint256((keccak256(abi.encodePacked(cap.cap_hash, _update.cap_hash))))));
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



}
