// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

library SlidingWindow {
    // each cycle contain 30 slot as limit.
    struct SlidingWindowState {
        uint256 startBlockTimestamp;
        uint40 blocksPerCycle;
        uint40 blocksPerSlot;
    }

    // @TODO
}