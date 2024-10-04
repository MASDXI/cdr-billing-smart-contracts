// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Billing Call Detail Records Interface
/// @author sirawt (@MASDXI)

import {CircularDoublyLinkedList as LinkedList} from "../libraries/CircularDoublyLinkedList.sol";

interface IBillingManager {
    enum SERVICE_TYPES {
        VOICE,
        DATA,
        SMS,
        RESERVED
    }

    struct CDR {
        SERVICE_TYPES service;
        uint256 timestamp;
        uint256 cost;
        uint256 balance;
        // @TODO other attribute?
    }

    struct Bill {
        uint256 outstandingBalance;
        mapping(uint256 => CDR) CDRs;
        LinkedList.List list;
    }

    error ErrorBillingInitialized();
    error ErrorBillingPaused();
    error ErrorBillingNotPaused();

    // @TODO other parameter?
    event CDRAdded(bytes16 indexed userId);
    event CDRRemoved(bytes16 indexed userId);
    event OutstandingBalanceDischarged(bytes16 indexed userId);
    event BillInitialized(bytes16 indexed userId);
    event BillingPaused(bytes16 indexed userId);
    event BillingUnpaused(bytes16 indexed userId);

    /// @custom:overloading addCDR() to specific cycle and slot?
    /// @custom:overloading removeCDR() from specific cycle and slot?
    /// @custom:overloading dischargeOutstandingBalanceOf() for partial, selective bill?
    function addCDR(bytes16 userId, CDR memory cdr) external;
    function removeCDR(bytes16 userId, uint256 index) external;
    function overdueBalanceOf(bytes16 userId) external view returns (uint256);
    function outstandingBalanceOf(
        bytes16 userId
    ) external view returns (uint256);
    function currentBillingCycleOf(
        bytes16 userId
    ) external view returns (uint256);
    function pausedBilling(bytes16 userId) external;
    function unpausedBilling(bytes16 userId) external;
    function statusBillingOf(bytes16 userId) external view returns (bool); // return true if billing not paused, false if paused
    function dischargeOutstandingBalanceOf(
        bytes16 userId,
        uint256 value
    ) external; // auto discharge for current
    function cdrOf(
        bytes16 userId,
        uint256 cycle
    ) external view returns (CDR[] memory);
    function cdrOf(
        bytes16 userId,
        uint256 cycle,
        uint8 slot
    ) external view returns (CDR[] memory);
}
