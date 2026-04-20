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
contract RebaseToken is ERC20 {
    error RebaseToken__interestRateCanOnlyDecrease(
        uint256 oldRate,
        uint256 newRate
    );

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e10; // rate per second

    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimeStamp;

    // event emitted when the global interest rate is updated
    event interestRateSet(uint256 newInterestRate);

    /// @notice Returns the current global interest rate
    function interestRate() external view returns (uint256) {
        return s_interestRate;
    }

    constructor() ERC20("RebaseToken", "RBT") {}
    /*
     * @notice Sets the global interest rate. This function can only be called by the contract owner and the new interest rate must be less than or equal to the current interest rate.
     * @param _newInterestRate The new interest rate to set.
     * @dev Thd interest rte can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external {
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken__interestRateCanOnlyDecrease(
                s_interestRate,
                _newInterestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit interestRateSet(_newInterestRate);
    }

    function mint(address _to, uint256 _mintAmount) external {
        _mintAccruedInterest[_to];
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _mintAmount);

    function balanceOf(address _user) public view override returns (uint256) {
        // get current principal, the number of tokens actually minted to the user
        // get the user's interest accrued , principal * interest accrued since last updated for user.
        return super.balanceOf[_user] * _calculateUserAccumulatedInterestSinceLastUpdate[_user];
    }

    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns(uint256 linearInterest) {
        // calculate the interest accrued since the last update for the user based on the difference between the user's individual interest rate and the current global interest rate, as well as the time elapsed since the last update.
        // calculate linear growth (principal +(principal * (userInterestRate - globalInterestRate) * timeElapsed))
        uint256 timeElapsed = block.timestamp - s-userLastUpdatedTimeStamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed))/ PRECISION_FACTOR;
    }

    function _mintAccruedInterest(address _user) internal {
        // find current balance minted to the user -> principal
        uint256 previousPrincipalBalance = super.balanceOf[_user];
        // calculate current balance including any interest accrued -> balanceOf
        uint256 currentBalance = balanceOf[_user];
        // calculate tokens to be minted to the user
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;
     
        // set updated timestamp
        
        s_userLastUpdatedTimeStamp[_user] = block.timestamp;

           // call _mint tokens to the user
           _mint(_user, balanceIncrease);

    }

    }
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
