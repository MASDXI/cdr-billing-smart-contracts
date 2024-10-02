// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Interface for Billing Call Detail Records
/// @author sirawt (@MASDXI)

import {CircularDoublyLinkedList as List} from "../libraries/CircularDoublyLinkedList.sol";

interface IBillingManager {
    enum SERVICE_TYPES { VOICE, DATA, SMS, RESERVED }

    struct CDR {
        SERVICE_TYPES service;
        uint256 timestamp;
        uint256 cost;
        // @TODO other attribute
    }

    struct Bill {
        uint256 outstandingBalance;
        mapping(uint256 => CDR) CDRs;
        List.List list;
    }

    struct Snapshot {
        uint256 cycle;
        uint8 slot;
        // @TODO other attribute
    }

    // @TODO other parameter
    event CDRAdded(bytes16 indexed userId);
    event CDRRemoved(bytes16 indexed userId);
    event OutstandingBalanceDischarged(bytes16 indexed userId);
    event BillingPaused(bytes16 indexed userId);
    event BillingUnpaused(bytes16 indexed userId);
   
    function initialBill(bytes16 userId) external;
    function addCDR(bytes16 userId, CDR memory cdr) external;
    function removeCDR(bytes16 userId, uint256 index) external; // is removeCDR() can edit past bill?
    function overdueBalanceOf(bytes16 userId) external view returns (uint256);
    function outstandingBalanceOf(bytes16  userId) external view returns (uint256);
    function currentBillingCycleOf(bytes16 userId) external view returns (uint256);
    function pausedBilling(bytes16 userId) external;
    function unpausedBilling(bytes16 userId) external;
    function statusBillingOf(bytes16 userId) external view returns (bool); // return true if billing not paused, false if paused
    function dischargeOutstandingBalanceOf(bytes16 userId, uint256 value) external;
    function dischargeOutstandingBalanceOf(bytes16 userId, uint256 bill, uint8 slot, uint256 value) external; // overloading for partial, selective bill  
    function cdrOfBill(bytes16 userId, uint256 cycle) external view returns (CDR [] memory);
    function cdrOfSlot(bytes16 userId, uint256 cycle, uint8 slot)  external view returns (CDR [] memory);
}