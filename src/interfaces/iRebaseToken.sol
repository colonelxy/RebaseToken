// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IRebaseToken
 * @dev Interface for the rebase token contract
 */
interface IRebaseToken {
    function mint(address _to, uint256 _amount) external;
    function burn(address _from, uint256 _amount) external;
}