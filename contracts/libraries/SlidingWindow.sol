// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// @dev Each cycle contains a fixed size of 30 slots, allowing for efficient lookup and traversal in a deterministic manner.

library SlidingWindow {
    struct State {
        uint256 startBlockNumber;
        uint256 snapShotCycle;
        uint8 snapShotSlot;
    }

    uint8 private constant DAYS = 30;
    uint8 private constant MINIMUM_BLOCK_TIME_IN_MILLISECONDS = 100;
    uint24 private constant MAXIMUM_BLOCK_TIME_IN_MILLISECONDS = 600_000;
    uint40 private constant MONTH_IN_MILLISECONDS = 2_629_746_000;

    error ErrorInvalidBlockTime();

    function _calculate(uint24 blockTime) internal pure returns (uint40 blocksPerCycle, uint40 blocksPerSlot) {
        if (blockTime < MINIMUM_BLOCK_TIME_IN_MILLISECONDS || blockTime > MAXIMUM_BLOCK_TIME_IN_MILLISECONDS) {
            revert ErrorInvalidBlockTime();
        }
        /// @custom:truncate https://docs.soliditylang.org/en/latest/types.html#division
        blocksPerSlot = (MONTH_IN_MILLISECONDS / blockTime) / DAYS;
        blocksPerCycle = blocksPerSlot * DAYS;
    }

    function update(State storage self, uint24 startBlockNumber) internal {
        self.startBlockNumber = startBlockNumber;
    }

    function snapshot(State storage self, uint24 blockTime, uint256 blockNumber) internal {
        (uint256 cycleCache, uint8 slotCache) = cycleAndSlot(self, blockTime, blockNumber);
        self.snapShotCycle = cycleCache;
        self.snapShotSlot = slotCache;
    }

    function loadSnapShot(State storage self) internal view returns (uint256 ,uint8) {
        return (self.snapShotCycle ,self.snapShotSlot);
    }

    function cycle(
        State storage self,
        uint24 blockTime,
        uint256 blockNumber
    ) internal view returns (uint256 value) {
        unchecked {
            (uint40 blocksPerCycleCache,) = _calculate(blockTime);
            uint256 startBlockNumberCache = self.startBlockNumber;
            // Calculate era based on the difference between the current block and start block.
            if (startBlockNumberCache > 0 && blockNumber > startBlockNumberCache) {
                value = (blockNumber - startBlockNumberCache) / blocksPerCycleCache;
            }
            // add snapShotCycle if not empty.
        }
    }

    function slot(
        State storage self,
        uint24 blockTime,
        uint256 blockNumber
    ) internal view returns (uint8 value) {
        unchecked {
            (uint40 blocksPerCycleCache,) = _calculate(blockTime);
            uint256 startBlockNumberCache = self.startBlockNumber;
            if (blockNumber > startBlockNumberCache) {
                value = uint8(((blockNumber - startBlockNumberCache) % blocksPerCycleCache) / (blocksPerCycleCache / DAYS));
            }
            // add snapShotSlot and calculate the actual current slot.
        }
    }

    function cycleAndSlot(
        State storage self,
        uint24 blockTime,
        uint256 blockNumber
    ) internal view returns (uint256, uint8) {
        return (cycle(self, blockTime, blockNumber), slot(self, blockTime, blockNumber));
    }
}
