// SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author Harold Achiando
 * @notice This is going to be a cross-chain token that incentivises users to deposit into a vault and gain interest. The token will be rebasing, meaning that the total supply will change over time based on the performance of the underlying assets in the vault. The token will be used to represent a share of the vault, and users will be able to redeem their tokens for a proportional share of the underlying assets.
 *@notice The interest rates in this token can only decrease.
 *@notice Each user will have an individual interest rate based on a global rate at the time of depositing. The global rate will decrease over time, and users will earn interest based on the difference between their individual rate and the current global rate.
 * @dev A simple ERC20 token that can be used for testing rebase functionality.
 *      This token does not implement any rebase logic itself, but can be used
 *      in conjunction with a rebase mechanism to simulate the effects of rebasing.
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
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
/**
 * @notice Constructor for the RebaseToken contract. Initializes the ERC20 token with the name "RebaseToken" and symbol "RBT", and sets the contract owner to the deployer of the contract.
     * @dev The constructor does not take any parameters and is called when the contract is deployed. It initializes the ERC20 token with the specified name and symbol, and sets the contract owner to the deployer of the contract using the Ownable constructor.
     */
    constructor() ERC20("RebaseToken", "RBT") Ownable(msg.sender){}

    function grantMinter&BurnerRole(address _account) external onlyOwner{
        _grantRole(MINTER_ROLE, _account);
        _grantRole(BURNER_ROLE, _account);
    }

    /**
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
    }

    /**
    * @notice Returns the balance of a user, including any interest accrued since their last update. This function overrides the standard ERC20 balanceOf function to include the calculation of accrued interest based on the user's individual interest rate and the current global interest rate.
        * @param _user The address of the user to retrieve the balance for.
        * @return The balance of the user, including any interest accrued since their last update.

     */

    function balanceOf(address _user) public view override returns (uint256) {
        // get current principal, the number of tokens actually minted to the user
        // get the user's interest accrued , principal * interest accrued since last updated for user.
        return super.balanceOf[_user] * _calculateUserAccumulatedInterestSinceLastUpdate[_user];
    }

/**
 * @notice Transfers a specified amount of tokens from the caller's balance to another address. This function should be called after minting accrued interest to ensure that the user's balance is up to date with the accrued interest.
     * @param _to The address of the recipient to transfer tokens to.
     * @param _amount The amount of tokens to transfer from the caller's balance to the recipient's balance. If the amount is set to uint256.max, it will transfer the entire balance of the caller.
     * @dev This function first calls the _mintAccruedInterest function for both the sender and recipient to ensure that their balances are up to date with the accrued interest, and then transfers the specified amount of tokens from the sender's balance to the recipient's balance. If the recipient's balance is zero before the transfer, their individual interest rate will be set to the sender's interest rate.
     */
    function transfer (address _to, uint256 _amount) public override returns(bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_to);

        if(_amount == type(uint256).max){
            _amount = balanceOf[msg.sender]
        };

        if(balanceOf(_to ==0){
            s_userInterestRate[_to] = s_userInterestRate[msg.sender]
        })
        return super.transfer(_to, _amount);
    }

    /**
     * @notice Transfers a specified amount of tokens from one address to another address. This function should be called after minting accrued interest for both the sender and recipient to ensure that their balances are up to date with the accrued interest.
     * @param _sender The address of the sender to transfer tokens from.
     * @param _recipient The address of the recipient to transfer tokens to.
     * @param _amount The amount of tokens to transfer from the sender's balance to the recipient's balance. If the amount is set to uint256.max, it will transfer the entire balance of the sender.
     * @dev This function first calls the _mintAccruedInterest function for both the sender and recipient to ensure that their balances are up to date with the accrued interest, and then transfers the specified amount of tokens from the sender's balance to the recipient's balance. If the recipient's balance is zero before the transfer, their individual interest rate will be set to the sender's interest rate.
     */

    function transferFrom (address _sender, address _recipient, uint256 _amount) public override returns(bool){
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);

        if(_amount == type(uint256).max){
            _amount = balanceOf[_sender]
        };

        if(balanceOf(_recipient ==0){
            s_userInterestRate[_recipient] = s_userInterestRate[_sender]
        })
        return super.transferFrom(_sender, _recipient, _amount);
    }

/**
    * @notice Calculates the interest accrued for a user since their last update. This function is used internally to calculate the interest accrued for a user based on the difference between their individual interest rate and the current global interest rate, as well as the time elapsed since their last update.
        * @param _user The address of the user to calculate the accrued interest for.
        * @return linearInterest The amount of interest accrued for the user since their last update, calculated using a linear growth formula based on the user's individual interest rate, the current global interest rate, and the time elapsed since their last update.

 */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns(uint256 linearInterest) {
        // calculate the interest accrued since the last update for the user based on the difference between the user's individual interest rate and the current global interest rate, as well as the time elapsed since the last update.
        // calculate linear growth (principal +(principal * (userInterestRate - globalInterestRate) * timeElapsed))
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimeStamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed))/ PRECISION_FACTOR;
    }
    /**
    * @notice Mints accrued interest to the user based on the difference between their individual interest rate and the current global interest rate, as well as the time elapsed since the last update. This function should be called before any minting or burning of tokens to ensure that the user's balance is up to date with the accrued interest.
        * @param _user The address of the user to mint interest for.
        * @dev This function calculates the interest accrued since the last update and mints the appropriate amount of tokens to the user. It also updates the user's last updated timestamp to the current block timestamp.
        */
    function _mintAccruedInterest(address _user) internal onlyRole(MINTER_ROLE) {
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

    
/**
 * @notice Burns a specified amount of tokens from the user's balance. This function should be called after any minting of accrued interest to ensure that the user's balance is up to date with the accrued interest.
     * @param _from The address of the user to burn tokens from.
     * @param _burnAmount The amount of tokens to burn from the user's balance.
     * @dev This function first calls the _mintAccruedInterest function to ensure that the user's balance is up to date with the accrued interest, and then burns the specified amount of tokens from the user's balance.
     */
    function burn(address _from, uint256 _burnAmount) external onlyRole(BURNER_ROLE) {
        if(_burnAmount == type(uint256).max) {
            _burnAmount = balanceOf[_from];
        }
        _mintAccruedInterest(_from);
        _burn(_from, _burnAmount);
    }
/**
    * @notice Returns the individual interest rate for a user. This function can be called by anyone to retrieve the individual interest rate for a specific user.
        * @param _user The address of the user to retrieve the individual interest rate for.
        * @return The individual interest rate for the specified user.

 */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
/** * @notice Returns the current global interest rate. This function can be called by anyone to retrieve the current global interest rate.
     * @return The current global interest rate.
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
};
