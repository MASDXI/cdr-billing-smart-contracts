// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

library CircularDoublyLinkedList {
    // no need to sort the node in list
    struct List {
        uint256 _size;
        mapping(uint256 => mapping(bool => uint256)) _nodes; // bidirection
        mapping(uint256 => bytes) _data;
    }

    // @TODO
}
