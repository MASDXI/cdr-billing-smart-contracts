// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Interface for Billing Call Detail Records
/// @author sirawt (@MASDXI)

import "./CircularDoublyLinkedList.sol";

interface IBilling {
    using CircularDoublyLinkedList for List;

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
        List list;
    }

    // @TODO other parameter
    event CDRAdded(bytes16 indexed userId);
    event CDRRemoved(bytes16 indexed userId);
    event OutstandingBalanceDischarged(bytes16 indexed userId);
   
    function initialBill(bytes16 userId) external;
    function addCDR(bytes16 userId, CDR memory cdr) external;
    function removeCDR(bytes16 userId, uint256 index) external; // is removeCDR can edit past bill?
    function overdueBalanceOf(bytes16 userId) external view returns (uint256);
    function outstandingBalanceOf(bytes16  userId) external view returns (uint256);
    function currentBillingCycleOf(bytes16 userId) external view returns (uint256);
    function dischargeOutstandingBalanceOf(bytes16 userId, uint256 value) external;
    function billOfCycle(bytes16 userId, uint256 cycle, uint8 slot) external view returns (CDR [] memory);
}