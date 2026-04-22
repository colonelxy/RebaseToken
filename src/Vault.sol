// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IRebaseToken} from "./interfaces/iRebaseToken.sol";

/**
 * @title Vault
 * @dev A simple vault contract for managing rebase tokens. This contract allows users to deposit and withdraw rebase tokens, and it keeps track of the total supply of the tokens in the vault. The vault is designed to work with a specific rebase token, which is specified at the time of deployment.
 */
contract Vault {
    // The address of the rebase token that this vault is associated with
    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);

    error Vault__RedeemFailed();

    // The constructor initializes the vault with the address of the rebase token
    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {
        // revert("Direct Ether transfers not allowed. Use the deposit function.");
    }
    /**
     * @dev Deposits Ether into the vault and mints rebase tokens for the sender. The amount of rebase tokens minted is equal to the amount of Ether deposited. This function emits a Deposit event to log the deposit action.
     */
    function deposit() external payable {
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }
    /**
     * @dev Redeems rebase tokens for Ether. The amount of Ether received is equal to the amount of rebase tokens burned. This function emits a Redeem event to log the redeem action.
     */
    function redeem(uint256 _redeemAmount) external {
        i_rebaseToken.burn(msg.sender, _redeemAmount);
        (bool success, ) = payable(msg.sender).call{value: _redeemAmount}("");

        if (!success) {
            revert Vault__RedeemFailed();
        }
    }
    /**
     * @dev Returns the address of the rebase token associated with the vault.
     * @return The address of the rebase token.
     */
    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
