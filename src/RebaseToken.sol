// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 * @title RebaseToken
 * @author Harold Achiando
 * @notice This is going to be a cross-chain token that incentivises users to deposit into a vault and gain interest. The token will be rebasing, meaning that the total supply will change over time based on the performance of the underlying assets in the vault. The token will be used to represent a share of the vault, and users will be able to redeem their tokens for a proportional share of the underlying assets.
 *@notice The interest rates in this token can only decrease.
 *@notice Each user will have an individual interest rate based on a global rate at the time of depositing. The global rate will decrease over time, and users will earn interest based on the difference between their individual rate and the current global rate.
 * @dev A simple ERC20 token that can be used for testing rebase functionality.
 *      This token does not implement any rebase logic itself, but can be used
 *      in conjunction with a rebase mechanism to simulate the effects of rebasing.
 */
contract RebaseToken is ERC20{
    error RebaseToken__interestRateCanOnlyDecrease(uint256 oldRate, uint256 newRate);

    uint256 private s_interestRate = 5e10;

    mapping(address => uint256) private s_userInterestRate;

    event inrerestRateSet(uint256 newInrerestRate);

    constructor()
        ERC20("RebaseToken", "RBT")
    {}
    function setInterestRate(uint256 _newInterestRate) external {
        if(_newInterestRate > s_interestRate )
        revert RebaseToken__interestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        s_interestRate = _newInterestRate;
        emit interestRateSet(_newInterestRate);
    }

    function mint(address _to, uint256 _mintAmount) external {
        _mint(_to, _mintAmount);
    }
}