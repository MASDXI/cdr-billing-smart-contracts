// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IBillingManager.sol";
import {SlidingWindow as slide} from "./libraries/SlidingWindow.sol";

/// @title Billing Call Detail Records Contract
/// @notice This contract is intended to be called exclusively by operators or service providers. It is not designed for direct retail actions by end-users.
/// @author sirawt (@MASDXI)

abstract contract BillingManager is SlidingWindow {
    using slide for slide.SlidingWindowState;
    // _bills[userId][cycles][slots]
    // Each cycle contains a fixed size of 30 slots, allowing for efficient lookup and traversal in a deterministic manner.
    // This mapping store the billing for each userId.
    mapping(bytes16 => mapping(uint256 => mapping(uint8 => Bill))) private _bills;
    // This mapping stores the entry point for each userId to calculate the start of their unique billing cycle.
    mapping(bytes16 => slide.SlidingWindowState) private _entryPoints;
    mapping(bytes16 => Snapshot) private _snapShots;

    // constructor () {}

    function initialBill(bytes16 userId) public {
        // @TODO
    }

    /// @dev add CDR to current bill
    function addCDR(bytes16 userId, CDR memory cdr) public {
        // @TODO
    }

    /// @dev remove CDR from current bill
    function removeCDR(bytes16 userId, uint256 index) public {
        // @TODO
    }

    // lookback the previous cycles, if the `outstandingBalance` is not zero and the bill is not empty, return it.
    function overdueBalanceOf(bytes16 userId) public view returns (uint256) {
        // @TODO
        return 0;
    }

    function outstandingBalanceOf(bytes16  userId) public view returns (uint256) {
        // @TODO
        return 0;
    }

    function currentBillingCycleOf(bytes16 userId) public view returns (uint256) {
        // @TODO
        return 0;
    }

    function dischargeOutstandingBalanceOf(bytes16 userId, uint256 value) public {
        // @TODO
    }

}