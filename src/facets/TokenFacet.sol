// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../libraries/LibDiamondStorage.sol";

contract TokenFacet {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function initToken(uint256 initialSupply) external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        ds.totalSupply = initialSupply;
        ds.balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function transfer(address _to, uint256 _amount) external returns (bool) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(ds.balances[msg.sender] >= _amount, "Insufficient balance");
        ds.balances[msg.sender] -= _amount;
        ds.balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;  
    }

    function balanceOf(address account) external view returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return ds.balances[account];
    }
}