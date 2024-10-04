// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./BillingManager.sol";

contract MockBillingManager is BillingManager {
    constructor (uint24 blockTime) BillingManager(blockTime) {}
}