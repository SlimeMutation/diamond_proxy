// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library LibDiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.storage");

    struct DiamondStorage {
        mapping(bytes4 => address) facets;
        address owner;
        uint256 totalSupply;
        mapping(address => uint256) balances;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        return ds;
    }
}
