// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

library CircularDoublyLinkedList {
    struct List {
        uint256 length;
        mapping(uint256 => mapping(bool => uint256)) nodes;
    }

    uint8 private constant RESERVED = 0;
    bool private constant NEXT = true;
    bool private constant PREV = false;

    function contains(
        List storage self,
        uint256 node
    ) internal view returns (bool) {
        return
            self.nodes[node][NEXT] > 0 ||
            self.nodes[node][PREV] > 0 ||
            self.nodes[RESERVED][NEXT] == node;
    }

    function next(
        List storage self,
        uint256 node
    ) internal view returns (uint256) {
        return self.nodes[node][NEXT];
    }

    function previous(
        List storage self,
        uint256 node
    ) internal view returns (uint256) {
        return self.nodes[node][PREV];
    }

    function first(List storage self) internal view returns (uint256) {
        return self.nodes[RESERVED][NEXT];
    }

    function last(List storage self) internal view returns (uint256) {
        return self.nodes[RESERVED][PREV];
    }

    function size(List storage self) internal view returns (uint256) {
        return self.length;
    }

    function add(List storage self, uint256 node) internal {
        if (!contains(self, node)) {
            uint256 lastNode = self.nodes[RESERVED][PREV];
            self.nodes[node][PREV] = lastNode;
            self.nodes[node][NEXT] = RESERVED;
            if (lastNode > RESERVED) {
                self.nodes[lastNode][NEXT] = node;
            } else {
                self.nodes[RESERVED][NEXT] = node; // If list was empty
            }
            self.nodes[RESERVED][PREV] = node;
            self.length++;
        }
    }

    function toArray(
        List storage self
    ) internal view returns (uint256[] memory) {
        uint256 length = self.length;
        uint256[] memory result = new uint256[](length);
        if (length > 0) {
            uint256 currentNode = self.nodes[RESERVED][NEXT];
            for (uint256 index = 0; index < length; index++) {
                result[index] = currentNode;
                currentNode = self.nodes[currentNode][NEXT];
            }
        }
        return result;
    }

    function remove(List storage self, uint256 node) internal {
        if (contains(self, node)) {
            uint256 prevNode = self.nodes[node][PREV];
            uint256 nextNode = self.nodes[node][NEXT];
            if (prevNode == RESERVED && nextNode == RESERVED) {
                self.nodes[RESERVED][NEXT] = RESERVED;
                self.nodes[RESERVED][PREV] = RESERVED;
            } else {
                if (prevNode > RESERVED) {
                    self.nodes[prevNode][NEXT] = nextNode;
                }
                if (nextNode > RESERVED) {
                    self.nodes[nextNode][PREV] = prevNode;
                }
            }
            self.nodes[node][PREV] = RESERVED;
            self.nodes[node][NEXT] = RESERVED;
            self.length--;
        }
    }
}
