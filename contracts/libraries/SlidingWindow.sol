// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

library SlidingWindow {
    // each cycle contain 30 slot as limit.

    //                                                         now
    //                                                          |
    // <-------------- cycle#1 ------------------><-- cycle#2 --->
    // [slot#1][slot#2][slot#3][slot#...][slot#30][slot#1][slot#2][slot#future]

    struct SlidingWindowState {
        uint256 startBlockNumber;
        uint40 blocksPerCycle; // need to be precise
        uint40 blocksPerSlot;
    }

    function getCurrentCycle(
        SlidingWindowState storage self,
        uint256 blockNumber
    ) internal view returns (uint256 cycle) {
        unchecked {
            uint256 startblockNumberCache = self.startBlockNumber;
            // Calculate era based on the difference between the current block and start block.
            if (
                startblockNumberCache > 0 && blockNumber > startblockNumberCache
            ) {
                cycle =
                    (blockNumber - startblockNumberCache) /
                    self.blocksPerCycle;
            }
        }
    }

    function getCurrentSlot(
        SlidingWindowState storage self,
        uint256 blockNumber
    ) internal view returns (uint8) {
        unchecked {
            uint256 startblockNumberCache = self.startBlockNumber;
            uint40 blockPerYearCache = self.blocksPerCycle;
            if (blockNumber > startblockNumberCache) {
                return
                    uint8(
                        ((blockNumber - startblockNumberCache) %
                            blockPerYearCache) / (blockPerYearCache / 30)
                    );
            }
        }
        return 0;
    }

    function getCurrentCycleAndSlot(
        SlidingWindowState storage self,
        uint256 blockNumber
    ) internal view returns (uint256, uint8) {
        //@TODO
        return (0, 0);
    }
}
