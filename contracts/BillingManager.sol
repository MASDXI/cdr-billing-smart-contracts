// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IBillingManager.sol";
import {CircularDoublyLinkedList as LinkedList} from "./libraries/CircularDoublyLinkedList.sol";
import {SlidingWindow as Slide} from "./libraries/SlidingWindow.sol";

/// @title Billing Call Detail Records Contract
/// @notice This contract is intended to be called exclusively by operators or service providers.
/// It is not designed for direct retail actions by end-users.
/// @author sirawt (@MASDXI)

abstract contract BillingManager is IBillingManager {
    using Slide for Slide.State;
    using LinkedList for LinkedList.List;

    mapping(bytes16 => bool) private _initial;
    mapping(bytes16 => bool) private _pause;
    
    mapping(bytes16 => mapping(uint256 => mapping(uint8 => Bill))) private _bills;
    mapping(bytes16 => Slide.State) private _slidingWindows;


    uint24 private _blockTime;

    modifier hasInit(bytes16 userId) {
        if (!_initial[userId]) {
            revert ErrorBillingInitialized();
        }
        _;
    }

    modifier whenPaused(bytes16 userId) {
        if (!_pause[userId]) {
            revert ErrorBillingNotPaused();
        }
        _;
    }

    modifier whenNotPaused(bytes16 userId) {
        if (_pause[userId]) {
            revert ErrorBillingPaused();
        }
        _;
    }

    constructor (uint24 blockTime) {
        _blockTime = blockTime;
    }

    function _updateBlockTime(uint24 blockTime) internal {
        _blockTime = blockTime;
    }

    /// @notice This function can be overridden for networks with sub-second block times 
    function _blockNumberProvider() internal view virtual returns (uint256) {
        return block.number;
    }
    
    function _init(bytes16 userId) internal {
        if (!_initial[userId]) {
            _initial[userId] = true;
            _slidingWindows[userId].update(_blockTime);
            emit BillInitialized(userId);
        }
    }

    function _currentBillPointer(bytes16 userId, uint256 blockNumber) private view returns (Bill storage) {
        (uint256 cycle, uint8 slot) = _slidingWindows[userId].cycleAndSlot(_blockTime, blockNumber);
        return _bills[userId][cycle][slot];
    }

    function _caculateOutstandingBalanceOf(bytes16 userId,uint256 cycle, uint8 slot) internal view returns (uint256 outstandingBalance) {
        outstandingBalance = _bills[userId][cycle][0].outstandingBalance;
        while (slot > 0) {
            uint slotOutstandingBalanceCache = _bills[userId][cycle][slot].outstandingBalance;
            if (slotOutstandingBalanceCache > 0) {
                outstandingBalance += slotOutstandingBalanceCache;
            }
            slot--;
            return outstandingBalance;
        }
    }

    function _caculateOverdueBalanceOf(bytes16 userId,uint256 cycle, uint8 slot) internal view returns (uint256 overdueBalance) {
        if (cycle > 0) {
            cycle--;
            overdueBalance = _bills[userId][cycle][0].outstandingBalance;
            while (slot > 0) {
                uint slotOutstandingBalanceCache = _bills[userId][cycle][slot].outstandingBalance;
                if (slotOutstandingBalanceCache > 0) {
                    overdueBalance += slotOutstandingBalanceCache;
                }
                slot--;
            }
            return overdueBalance;
        }
    }

    /// @custom:inefficient all CDRs under cycle can be large
    function cdrOf(bytes16 userId, uint256 cycle) public virtual override view hasInit(userId) returns (CDR[] memory) {
        uint256 totalCDRCountCache = 0;
        for (uint8 slot = 0; slot < 30; slot++) {
            uint256 size = _bills[userId][cycle][slot].list.size();
            totalCDRCountCache += size; // Count all CDRs across slots
        }
        CDR[] memory cdrsCache = new CDR[](totalCDRCountCache);
        uint256 index = 0; // Initialize index to 0
        for (uint8 slot = 0; slot < 30; slot++) {
            uint256[] memory templist = _bills[userId][cycle][slot].list.toArray();
            for (uint256 i = 0; i < templist.length; i++) { // Change to start at 0
                cdrsCache[index] = _bills[userId][cycle][slot].CDRs[templist[i]];
                index++;
            }
        }
        return cdrsCache;
    }

    function cdrOf(bytes16 userId, uint256 cycle, uint8 slot) public virtual override view hasInit(userId) returns (CDR [] memory) {
        uint256[] memory templist = _bills[userId][cycle][slot].list.toArray(); // Get the array of nodes
        CDR[] memory cdrsCache = new CDR[](templist.length); // Initialize cache for CDRs
        for (uint256 i = 0; i < templist.length; i++) { // Iterate over the length of the templist
            cdrsCache[i] = _bills[userId][cycle][slot].CDRs[templist[i]]; // Retrieve CDRs using the node identifiers
        }

        return cdrsCache; // Return the filled array of CDRs
    }

    function currentBillingCycleOf(bytes16 userId) public virtual override view hasInit(userId) returns (uint256) {
        if (_pause[userId]) {
            (uint256 cycle,) = _slidingWindows[userId].loadSnapShot();
            return cycle;
        } else {
            return _slidingWindows[userId].cycle(_blockTime, _blockNumberProvider());
        }
    }

    function currentSizeOfCDRs(bytes16 userId) public virtual view hasInit(userId) returns (uint256) {
        Bill storage bill = _currentBillPointer(userId, _blockNumberProvider());
        return bill.list.size();
    }

    function outstandingBalanceOf(bytes16  userId) public override view hasInit(userId) returns (uint256) {
        if (_pause[userId]) {
            (uint256 cycle, uint8 slot) = _slidingWindows[userId].loadSnapShot();
            return _caculateOutstandingBalanceOf(userId, cycle, slot);
        } else {
            (uint256 cycle, uint8 slot) = _slidingWindows[userId].cycleAndSlot(_blockTime, _blockNumberProvider());
            return _caculateOutstandingBalanceOf(userId, cycle, slot);
        }
    }

    /// @custom:integrity May return zero if too much time has passed.
    /// Calculates overdue balance by checking previous cycle and slots for outstanding amounts.
    function overdueBalanceOf(bytes16 userId) public override view returns (uint256)  {
        if (_pause[userId]) {
            (uint256 cycle, uint8 slot) = _slidingWindows[userId].loadSnapShot();
            return _caculateOverdueBalanceOf(userId, cycle, slot);
        } else {
            (uint256 cycle, uint8 slot) = _slidingWindows[userId].cycleAndSlot(_blockTime, _blockNumberProvider());
            return _caculateOverdueBalanceOf(userId, cycle, slot);
        }
    }

    function statusBillingOf(bytes16 userId) public override view returns (bool){
        return _pause[userId];
    }

    function addCDR(bytes16 userId, CDR memory record) public virtual override whenNotPaused(userId) {
        if (!_initial[userId]) {
            _init(userId);
        }
        Bill storage bill = _currentBillPointer(userId, _blockNumberProvider());
        uint256 index = bill.list.size() + 1;
        bill.CDRs[index] = record;
        bill.oustandingBalance += record.outstandingBalance;
        bill.list.add(index);
        emit CDRAdded(userId);
    }

    function removeCDR(bytes16 userId, uint256 index) public virtual override hasInit(userId) whenNotPaused(userId) {
        Bill storage bill = _currentBillPointer(userId, _blockNumberProvider());
        if (bill.list.contains(index)) {
            delete bill.CDRs[index];
            bill.list.remove(index);
            emit CDRRemoved(userId);
        }
    }

    function dischargeOutstandingBalanceOf(bytes16 userId, uint256 value) public virtual override hasInit(userId) {
        Bill storage bill = _currentBillPointer(userId, _blockNumberProvider());
        if (outstandingBalanceOf(userId) > 0) {
            // @TODO first-in-first-out discharge
        }
        emit OutstandingBalanceDischarged(userId);
    }

    function pausedBilling(bytes16 userId) public virtual override hasInit(userId) whenNotPaused(userId) {
        _slidingWindows[userId].snapshot(_blockTime, _blockNumberProvider());
        _pause[userId] = true;
        emit BillingPaused(userId);
    }

    function unpausedBilling(bytes16 userId) public virtual override hasInit(userId) whenPaused(userId) {
        // @TODO load snapshot
        _pause[userId] = false;
        emit BillingUnpaused(userId);
    }

}