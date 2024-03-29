// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IOptimisticPool.sol";

interface IOptimisticPool {
    function addClaim() external;

    function checkClaim() external returns (bool);
}
