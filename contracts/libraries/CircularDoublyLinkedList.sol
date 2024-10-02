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

    function contains(List storage self, uint256 node) internal view returns (bool) {
        return (self.nodes[RESERVED][PREV] > RESERVED || self.nodes[RESERVED][NEXT] == node);
    }

    function next(List storage self, uint256 node) internal view returns (uint256) {
        return self.nodes[node][NEXT];
    }

    function previous(List storage self, uint256 node) internal view returns (uint256) {
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
            self.nodes[node][PREV] = self.nodes[RESERVED][PREV];
            self.nodes[node][NEXT] = RESERVED;
            self.length++;
        }
    }

    function toArray(List storage self) internal view returns (uint256 [] memory) {
        uint256 length = self.length;
        uint256[] memory result = new uint256[](length);
        if (length > 0) {
            uint256 currentNode = self.nodes[RESERVED][NEXT];
            for (uint256 i = 0; i < self.length; i++) {
                result[i] = currentNode;
                currentNode = self.nodes[currentNode][NEXT];
            }
            return result;
        } else {
            assembly {
                mstore(result, 0)
            }
            return result;
        }
    }

    function remove(List storage self, uint256 node) internal {
        if (contains(self, node)) {
            uint256 prevNode = self.nodes[node][PREV];
            uint256 nextNode = self.nodes[node][NEXT];
            self.nodes[prevNode][NEXT] = nextNode;
            self.nodes[nextNode][PREV] = prevNode;
            self.nodes[node][PREV] = RESERVED;
            self.nodes[node][NEXT] = RESERVED;
            self.length--;
        }
    }
}
