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

    function statusBillingOf(bytes16 userId) public override view returns (bool){
        return _pause[userId];
    }

    function overdueBalanceOf(bytes16 userId) public override view  returns (uint256 overdueBalance)  {
        (uint256 cycle, uint8 slot) = _slidingWindows[userId].cycleAndSlot(_blockTime, _blockNumberProvider());
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
        }
    }

    function outstandingBalanceOf(bytes16  userId) public override view hasInit(userId) returns (uint256 outstandingBalance) {
        (uint256 cycle, uint8 slot) = _slidingWindows[userId].cycleAndSlot(_blockTime, _blockNumberProvider());
        outstandingBalance = _bills[userId][cycle][0].outstandingBalance;
        while (slot > 0) {
            uint slotOutstandingBalanceCache = _bills[userId][cycle][slot].outstandingBalance;
            if (slotOutstandingBalanceCache > 0) {
                outstandingBalance += slotOutstandingBalanceCache;
            }
            slot--;
        }
    }

    function currentBillingCycleOf(bytes16 userId) public virtual override view hasInit(userId) returns (uint256) {
        return _slidingWindows[userId].cycle(_blockTime, _blockNumberProvider());
    }

    /// @custom:inefficient CDRs can be large
    function cdrOf(bytes16 userId, uint256 cycle) public virtual override view hasInit(userId) returns (CDR [] memory) {
        Bill storage bill = _currentBillPointer(userId, _blockNumberProvider());
        // @TODO loop
        CDR [] memory CDRs;
        return CDRs;
    }

    function cdrOf(bytes16 userId, uint256 cycle, uint8 slot) public virtual override view hasInit(userId) returns (CDR [] memory) {
        uint256 [] memory templist = _bills[userId][cycle][slot].list.toArray();
        uint256 length = templist.length;
        CDR [] memory cdrs = new CDR[](length);
        for (uint256 i = 0; i < length; i++) {
            cdrs[i] = _bills[userId][cycle][slot].CDRs[templist[i]];
        }
        return cdrs;
    }

    function addCDR(bytes16 userId, CDR memory record) public virtual override whenNotPaused(userId) {
        if (!_initial[userId]) {
            _init(userId);
        }
        Bill storage bill = _currentBillPointer(userId, _blockNumberProvider());
        uint256 index = bill.list.size() + 1;
        bill.CDRs[index] = record;
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
        // @TODO first-in-first-out discharge
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