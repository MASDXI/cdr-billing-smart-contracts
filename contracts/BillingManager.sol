// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IBillingManager.sol";
import {SlidingWindow as slide} from "./libraries/SlidingWindow.sol";

/// @title Billing Call Detail Records Contract
/// @notice This contract is intended to be called exclusively by operators or service providers.
/// It is not designed for direct retail actions by end-users.
/// @author sirawt (@MASDXI)

// userId1 Bill
//                             current
//                                |
// <------ cycle 1 ------><- cycle 2->
// [slot][slot][...][slot][slot][slot]

// userId 2 Bill
//                             current
//                                |
// <- cycle 7 -----><--- cycle 8 ---->
// [slot][slot][...][slot][slot][slot]

abstract contract BillingManager is IBillingManager {
    using slide for slide.SlidingWindowState;

    mapping(bytes16 => bool) private _initial;
    // _bills[userId][cycles][slots]
    // Each cycle contains a fixed size of 30 slots, allowing for efficient lookup and traversal in a deterministic manner.
    // This mapping store the billing for each userId.
    mapping(bytes16 => mapping(uint256 => mapping(uint8 => Bill))) private _bills;
    // This mapping stores the entry point for each userId to calculate the start of their unique billing cycle.
    mapping(bytes16 => slide.SlidingWindowState) private _entryPoints;    
    mapping(bytes16 => Snapshot) private _snapShots;


    modifier hasInit(bytes16 userId) {
        if (!_initial[userId]) {
            revert();
        }
        _;
    }


    // constructor () {}

    function _init(bytes16 userId) internal {
        if (!_initial[userId]) {
            _initial[userId] = true;
            // emit BillInitialized(userId);
        }
    }

    /// @notice This function can be overridden for networks with sub-second block times 
    function _blockNumberProvider() internal view virtual returns (uint256) {
        return block.number;
    } 

    /// @dev add CDR to current bill
    function addCDR(bytes16 userId, CDR memory cdr) public {
        // initial the bill if not initialized before
        if (!_initial[userId]) {
            _init(userId);
        }
        // Bill storage bill = _current(userId, _blockNumberProvider());
        // uint256 index = bill.list.size() + 1;
        // bill.CDRs[index] = cdr;
        // bill.list.add(index);
        emit CDRAdded(userId);
    }

    /// @dev remove CDR from current bill
    function removeCDR(bytes16 userId, uint256 index) public hasInit(userId) {
        // Bill storage bill = _current(userId, _blockNumberProvider());
        // delete bill.CDRs[index];
        // bill.list.remove(index);
        emit CDRRemoved(userId);
    }

    // lookback the previous cycles, if the `outstandingBalance` is not zero and the bill is not empty, return it.
    function overdueBalanceOf(bytes16 userId) public view returns (uint256) {
        // @TODO
        // if bill not initial return 0
        // return _caclulateOverdueBalanceOf(userId, _blockNumberProvider());
        return 0;
    }

    function outstandingBalanceOf(bytes16  userId) public view returns (uint256) {
        // @TODO
        // if bill not initial return 0
        // return    // _calculateOutstandingBalanceOf(userId, _blockNumberProvider());
        return 0;
    }

    /// @return return the current cycle
    function currentBillingCycleOf(bytes16 userId) public view returns (uint256) {
        // @TODO
        return 0;
    }

    function cdrOfBill(bytes16 userId, uint256 cycle) external view hasInit(userId) returns (CDR [] memory) {
        // @TODO
        // if bill not initial return empty CDRs
        CDR [] memory CDRs;
        return CDRs;
    }
    function cdrOfSlot(bytes16 userId, uint256 cycle, uint8 slot)  external view hasInit(userId) returns (CDR [] memory) {
        // @TODO
        // if bill not initial return empty CDRs
        CDR [] memory CDRs;
        return CDRs;
    }

    function dischargeOutstandingBalanceOf(bytes16 userId, uint256 value) public hasInit(userId) {
        // @TODO full
        emit OutstandingBalanceDischarged(userId);
    }

    function dischargeOutstandingBalanceOf(bytes16 userId, uint256 bill, uint8 slot, uint256 value) public hasInit(userId) {
        // @TODO partial
        emit OutstandingBalanceDischarged(userId);
    }

    function pausedBilling(bytes16 userId) public hasInit(userId) {
        // @TODO
        // store snapshot
        emit BillingPaused(userId);
    }

    function unpausedBilling(bytes16 userId) public hasInit(userId) {
        // @TODO
        // load snapshot
        emit BillingUnpaused(userId);
    }

}